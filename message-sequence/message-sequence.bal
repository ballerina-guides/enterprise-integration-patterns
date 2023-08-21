import ballerina/io;
import ballerina/http;

final http:Client s3Client = check new ("http://coral.s3.us.amazonaws.com.balmock.io");

public function main() returns error? {
    http:Response metaData = check s3Client->/employee_names.head();
    float fileSize = check float:fromString((check metaData.getHeader("Content-Length")));

    int numberOfPackets = <int> float:ceiling(fileSize/10);
    byte[] receivedData = [];
    // Download the data part by part.
    foreach int i in 0...numberOfPackets-1 {
        http:Response s3Response = check s3Client->/employee_names.get(
            headers = {
                Range: string `bytes=${10 * i}-${10 * (i + 1) - 1}`
            }
        );
        byte[]|error partData = s3Response.getBinaryPayload();
        if partData is error || s3Response.statusCode != 200 {
            break;
        }
        receivedData.push(...partData);
    }
    check io:fileWriteBytes("./resources/employee_names.txt", receivedData);
}
