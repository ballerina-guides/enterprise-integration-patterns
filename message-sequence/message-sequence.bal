import ballerina/io;
import ballerina/http;

type S3Response record {|
    string x\-amz\-id;
    string x\-amz\-request\-id;
    string x\-amz\-server\-side\-encryption?;
|};

public function main() returns error? {
    http:Client s3Client = check new ("http://asics-shoes.s3.amazonaws.com.balmock.io");

    // Reads file as stream containing 4kb chunk.
    stream<io:Block, io:Error?> fileStream = check io:fileReadBlocksAsStream("./resources/employee_names.txt", 4096);

    map<string> s3Headers = {
        x\-amz\-acl: "private",
        x\-amz\-storage\-class: "STANDARD",
        x\-amz\-checksum\-algorithm: "CRC32",
        x\-amz\-server\-side\-encryption: "AES256"
    };

    http:Request request = new;

    foreach var [key, value] in s3Headers.entries() {
        request.addHeader(key, value);    
    }

    check from io:Block chunk in fileStream
        do {
            request.setBinaryPayload(chunk);
            S3Response response = check s3Client->/uploads.post(request);
            io:println(response);
        };
}
