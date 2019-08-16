package main

import (
	"errors"
	"github.com/grafana-tools/sdk"
	"io/ioutil"
	"log"
	"time"
)

type Dashboard struct {
	client        *sdk.Client
	board         *sdk.Board
	grafUrl       string
	promUrl       string
	panelTemplate []byte
}

//findDsWithUrl searches for a datasource within a grafana instance based on URL
func findDsWithUrl(matchURL string, dsList []sdk.Datasource) (*sdk.Datasource, error) {
	for _, dsB := range dsList {
		if matchURL == dsB.URL {
			return &dsB, nil
		}
	}
	return nil, errors.New("Data source url not found")
}

// Setup configures a dashboard object to talk to a grafana instance within a time period
func (d *Dashboard) Setup(title string, apiKey string, grafUrl string, start time.Time, end time.Time) {
	log.Print("Setting up grafana client\n")

	d.grafUrl = grafUrl
	d.client = sdk.NewClient(d.grafUrl, apiKey, sdk.DefaultHTTPClient)

	log.Printf("Creating dashboard %s", title)
	d.board = sdk.NewBoard(title)
	d.board.Timezone = "utc"
	d.board.Time = sdk.Time{
		From: start.Format("2006-01-02 15:04:05Z"),
		To:   end.Format("2006-01-02 15:04:05Z"),
	}
}

// NewPrometheusDs configures a prometheus data source within grafana that is compatable with
// the dashboard object
func (d *Dashboard) NewPrometheusDs(url string) error {
	d.promUrl = url
	existingDS, err := d.client.GetAllDatasources()
	if err != nil {
		return err
	}

	_, err = findDsWithUrl(url, existingDS)
	if err != nil {
		log.Print("Building new Prometheus datasource")
		newDs := sdk.Datasource{
			Name:      "Prometheus",
			Type:      "prometheus",
			URL:       url,
			Access:    "direct",
			BasicAuth: func() *bool { b := false; return &b }(),
			IsDefault: true,
			JSONData: map[string]string{
				"timeInterval": "1s",
			},
		}
		_, err := d.client.CreateDatasource(newDs)
		time.Sleep(5)
		return err
	} else {
		log.Print("Datasource with duplicate URL found. Utilizing original datasource")
	}

	return err
}

// LoadPanelTemplate loads a pre-defined grafana panel template from a file name fn
func (d *Dashboard) LoadPanelTemplate(fn string) error {
	var err error
	d.panelTemplate, err = ioutil.ReadFile(fn)
	return err
}

// AddGraph generates a new graph within a grafana dashboard
func (d *Dashboard) AddGraph(title string, query string) error {
	log.Printf("Adding graph '%s'", title)
	row := d.board.AddRow(title)

	var graph sdk.Panel
	err := graph.UnmarshalJSON(d.panelTemplate)
	if err != nil {
		return err
	}

	graph.AddTarget(&sdk.Target{
		Expr: query,
	})
	row.AddGraph(graph.GraphPanel)
	// log.Print(row.Panels[:len(row.Panels)-1])
	graph.Title = title

	return err
}

//Update updates the dashboard if it alread exists in Grafana. Otherwise, create a new one.
//If the current dashboard is found to already exist, it is deleted and a new
//board of the same name is written. This is necessary because the API
//overwrite function cannot dynamically update number of graphs
func (d *Dashboard) Update() error {
	res, err := d.client.SearchDashboards(d.board.Title, false)
	if err != nil {
		return err
	}
	if len(res) > 0 && res[0].Title == d.board.Title {
		log.Print("Overwritting existing dashboard")
		_, err = d.client.DeleteDashboard(res[0].URI)
		if err != nil {
			return err
		}
		err = d.client.SetDashboard(*d.board, false)
	} else {
		log.Print("Creating new dashboard")
		err = d.client.SetDashboard(*d.board, false)
	}
	return err
}
