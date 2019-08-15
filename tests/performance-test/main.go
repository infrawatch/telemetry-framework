package main

import (
	"encoding/json"
	"io/ioutil"
	"log"
	"os/exec"
	"strconv"
	"strings"
	"time"
)

type PerformanceTest struct {
	db    *Dashboard
	p     *Parser
	err   error
	start time.Time
	end   time.Time
}

func (pt *PerformanceTest) Err() error {
	return pt.err
}

func (pt *PerformanceTest) InitDashboard(title string) {
	if pt.err != nil {
		return
	}
	pt.db = new(Dashboard)

	var data []byte
	data, pt.err = ioutil.ReadFile("/performance-test/grafana/apikey")
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

	pt.err = pt.db.NewPrometheusDs("http://" + hosts["prometheus-host"])
	if pt.err != nil {
		return
	}

	pt.err = pt.db.LoadPanelTemplate("/performance-test/grafana/graph-template.json")
}

func (pt *PerformanceTest) InitParser() {
	if pt.err != nil {
		return
	}
	pt.p = new(Parser)
	pt.err = pt.p.LoadTests("/performance-test/config/test-configs.yml")
}

func (pt *PerformanceTest) ExecTest(index int) error {
	var out []byte
	test := pt.p.Tests()[index]
	log.Print("Running test of length " + strconv.FormatUint(test.Spec.Length, 10) + "s")

	args := pt.p.ArgStrings(test)
	out, err := exec.Command("/performance-test/exec/unit-test.sh", args...).Output()
	if err != nil {
		return err
	}

	for _, output := range strings.Split(string(out), "\n") {
		if output != "" {
			log.Print(output)
		}
	}
	log.Print("Cooling down for 30 seconds")
	time.Sleep(time.Second * time.Duration(30))

	return err
}

func (pt *PerformanceTest) Run() {
	if pt.err != nil {
		return
	}

	for i, test := range pt.p.Tests() {

		pt.start, pt.end = pt.p.GetTimes(i)
		pt.start = pt.start.Add(time.Second * -10)
		pt.end = pt.end.Add(time.Second * 30)

		log.Printf("Generating dashboard '%s' from %s to %s", test.Metadata.Name, pt.start, pt.end)

		pt.InitDashboard(test.Metadata.Name)
		if pt.err != nil {
			return
		}
		pt.err = pt.ExecTest(i)

		for _, query := range test.Spec.Queries {
			pt.err = pt.db.AddGraph(string(query), string(query))
			if pt.err != nil {
				return
			}
		}

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
