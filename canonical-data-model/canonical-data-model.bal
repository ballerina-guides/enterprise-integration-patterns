import ballerina/http;

const PROJECT_ID = "LAND-TEST04";
const DATASET_ID = "f57074a0-a8b6-403e-9df1-e9fc46";

final http:Client gMapClient = check new ("http://mapsplatformdatasets.googleapis.com.balmock.io");

enum TARGET_TYPE {
    KML,
    GEOJSON
}

type GeoJson record {
    string 'type = "FeatureCollection";
    string name;
    Feature[] features;
};

type Feature record {|
    string 'type = "Feature";
    record {|
        string X;
        string Y;
        string Name;
        string description;
    |} properties;
    record {|
        string 'type = "Point";
        string[] coordinates;
    |} geometry;
|};

type GMapResponse record {
    string name;
    string displayName;
    string createTime;
};

service /api on new http:Listener(8080) {
    resource function post uploadCsvDataToGMap(string[][] data) returns GMapResponse|error? {
        xml|GeoJson kmlData = check canonicalDataModel(data, KML);
        if kmlData is GeoJson {
            return error("Unsupported target type");
        }
        GMapResponse gMapResponse = check gMapClient->post(
            string `v1/projects/${PROJECT_ID}/datasets/${DATASET_ID}:import`, kmlData);
        return gMapResponse;
    }

    resource function post uploadGpxDataToGMap(xml data) returns GMapResponse|error? {
        xml|GeoJson kmlData = check canonicalDataModel(data, KML);
        if kmlData is GeoJson {
            return error("Unsupported target type");
        }
        GMapResponse gMapResponse = check gMapClient->post(
            string `v1/projects/${PROJECT_ID}/datasets/${DATASET_ID}:import`, kmlData);
        return gMapResponse;
    }
}

isolated function canonicalDataModel(anydata data, string targetType) returns xml|GeoJson|error {
    GeoJson canonicalJsonRepresentation;
    match targetType {
        "KML" => {
            if data is string[][] {
                canonicalJsonRepresentation = convertFromCsvToGeoJson(data);
            } else if data is xml {
                canonicalJsonRepresentation = convertFromGpxToGeoJson(data);
            } else {
                return error("Unsupported source type");
            }
            return convertFromGeoJsonToKml(canonicalJsonRepresentation);
        }
        "GEOJSON" => {
            if data is string[][] {
                canonicalJsonRepresentation = convertFromCsvToGeoJson(data);
            } else if data is xml {
                canonicalJsonRepresentation = convertFromGpxToGeoJson(data);
            } else {
                return error("Unsupported source type");
            }
            return canonicalJsonRepresentation;
        }
        _ => {
            return error("Unsupported target type");
        }
    }
}

isolated function convertFromCsvToGeoJson(string[][] data) returns GeoJson {
    GeoJson geoJsonData = {
        'type: "FeatureCollection",
        name: "Placemarks",
        features: []
    };

    foreach [int, string[]] [i, element] in data.enumerate() {
        if i == 0 {
            continue;
        }
        geoJsonData.features[i - 1] = {
            properties: {X: element[0], Y: element[1], Name: element[2], description: element[3]},
            geometry: {coordinates: [element[0], element[1]]}
        };
    }
    return geoJsonData;
}

isolated function convertFromGpxToGeoJson(xml gpxData) returns GeoJson {
    GeoJson geoJsonData = {
        'type: "FeatureCollection",
        name: "Placemarks",
        features: []
    };

    int i = 0;
    foreach xml extension in gpxData/**/<extensions> {
        string coordinateX = (extension/**/<X>).data();
        string coordinateY = (extension/**/<Y>).data();
        geoJsonData.features[i] = {
            properties: {
                X: coordinateX,
                Y: coordinateY,
                Name: (extension/**/<Name>).data(),
                description: (extension/**/<description>).data()
            },
            geometry: {coordinates: [coordinateX, coordinateY]}
        };
        i += 1;
    }
    return geoJsonData;
}

isolated function convertFromGeoJsonToKml(GeoJson geoJsonData) returns xml|error {
    xml kmlData = xml `<?xml version="1.0" encoding="UTF-8"?>`;
    xml:Element kmlElement = xml `<kml>
    </kml>`;
    xml:Element docElement = xml `<Document>
            <Schema id="temp">
                <SimpleField name="X" type="double"/>
                <SimpleField name="Y" type="double"/>
                <SimpleField name="Name" type="string"/>
            </Schema>
        </Document>`;

    foreach Feature feature in geoJsonData.features {
        xml placeMark = xml `
            <Placemark>
                <description>${feature.properties.description}</description>
                <Point><coordinates>${feature.geometry.coordinates[0]},${feature.geometry.coordinates[1]}</coordinates></Point>
            </Placemark>
        `;
        xml e = docElement.getChildren() + placeMark;
        xml:setChildren(docElement, e);
    }
    kmlElement.setChildren(docElement);
    return xml:concat(kmlData, kmlElement);
}
