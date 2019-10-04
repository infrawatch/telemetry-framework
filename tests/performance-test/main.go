package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"strconv"
	"time"
)

type PerformanceTest struct {
	db    *Dashboard
	p     *Parser
	err   error
	start time.Time
	end   time.Time
}

// Err allows for better error handling by blocking class functionality if
// an error occurs within a performance test. This minimizes the amount
// of error checks necessary in code
func (pt *PerformanceTest) Err() error {
	return pt.err
}

// InitDashboard generates a new dashboard in grafana with a pre-loaded graph panel template
func (pt *PerformanceTest) InitDashboard(title string) {
	if pt.err != nil {
		return
	}
	pt.db = new(Dashboard)

	var data []byte
	data, pt.err = ioutil.ReadFile("/tmp/grafana_apikey")
	if pt.err != nil {
		return
	}
	var apiKeyMap map[string]string
	pt.err = json.Unmarshal(data, &apiKeyMap)
	if pt.err != nil {
		return
	}
	var hostFile []byte
	hostFile, pt.err = ioutil.ReadFile("/performance-test/config/hosts.json")
	if pt.err != nil {
		return
	}
	var hosts map[string]string
	pt.err = json.Unmarshal(hostFile, &hosts)
	if pt.err != nil {
		return
	}

	pt.db.Setup(title, string(apiKeyMap["key"]), "http://"+hosts["grafana-host"], pt.start, pt.end)

	log.Print("Creating SAF prometheus datasource")
	pt.err = pt.db.NewPrometheusDs("http://"+hosts["prometheus-host"], "SAFPrometheus")
	if pt.err != nil {
		return
	}
	log.Print("Creating OCP prometheus datasource")
	pt.err = pt.db.NewPrometheusDs("http://"+hosts["ocp-prometheus-host"], "OCPPrometheus")
	if pt.err != nil {
		return
	}

	//TODO: delete this
	//pt.err = pt.db.LoadPanelTemplate("/performance-test/grafana/graph-template.json")

	log.Print("Loading dashboard template...")
	pt.err = pt.db.LoadDashboardTemplate("/performance-test/grafana/perftest-dashboard.json")
}

//InitParser creates a parser object with the test config file loaded into it
func (pt *PerformanceTest) InitParser() {
	if pt.err != nil {
		return
	}
	pt.p = new(Parser)
	pt.err = pt.p.LoadTests("/performance-test/config/test-configs.yml")
}

//ExecTest runs a performance test configuration
func (pt *PerformanceTest) ExecTest(index int) error {
	test := pt.p.Tests()[index]
	log.Print("Running test of length " + strconv.FormatUint(test.Spec.Length, 10) + "s")

	args := pt.p.ArgStrings(test)
	cmd := exec.Command("/performance-test/exec/launch-test.sh", args...)
	cmd.Stderr = cmd.Stdout
	cmdReader, err := cmd.StdoutPipe()
	if err != nil {
		return err
	}
	cmd.Start()

	scanner := bufio.NewScanner(cmdReader)
	for scanner.Scan() {
		log.Print(scanner.Text())
	}
	if err := scanner.Err(); err != nil {
		fmt.Fprintln(os.Stderr, "reading standard input:", err)
	}

	log.Print("Cooling down for 30 seconds")
	time.Sleep(time.Second * time.Duration(30))

	return err
}

//Run executes a sequence of performance tests and generates dashboards and graphs for each in grafana
func (pt *PerformanceTest) Run() {
	if pt.err != nil {
		return
	}

	for i, test := range pt.p.Tests() {

		pt.start, pt.end = pt.p.GetTimes(i)
		// BUG? These values depend on test pod startup time
		pt.start = pt.start.Add(time.Second * -60) // Add lead time to the dashboard
		pt.end = pt.end.Add(time.Second * 60)      // Add cool-down time to the dashboard

		log.Printf("Generating dashboard '%s' from %s to %s", test.Metadata.Name, pt.start, pt.end)

		pt.InitDashboard(test.Metadata.Name)
		if pt.err != nil {
			return
		}
		pt.err = pt.ExecTest(i)

		/*for _, query := range test.Spec.Queries {
			pt.err = pt.db.AddGraph(string(query), string(query))
			if pt.err != nil {
				return
			}
		}*/

		pt.err = pt.db.Update()
		if pt.err != nil {
			return
		}
	}
}

func main() {
	pt := new(PerformanceTest)
	pt.InitParser()
	pt.Run()

	if pt.Err() != nil {
		log.Fatal(pt.Err())
	}
}
