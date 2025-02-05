This test project is used to demonstrate the issue of inaccurate upload progress and retry mechanism when uploading small data chunks with NSURLSession. The related question has been raised and discussed on the Apple Developer Forums: https://developer.apple.com/forums/thread/773813

---

I recently encountered an issue with incorrect progress reporting and timeout behavior when using `NSURLSession` to upload small data buffers.

# Background
In my app, I split a large video file into smaller 1MB chunk files for upload. This approach facilitates error retries and concurrent uploads. Additionally, I monitor the upload speed for each request, and if the speed is too slow, I switch CDNs to re-upload the chunk.

# Issue Description
When using `NSURLSessionUploadTask` or `NSURLSessionDataTas`k to upload a 1MB HTTP body, I noticed that the progress callbacks are not accurate. I rely on the following callback to track progress:

```
- (void)URLSession:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:
```

Even when using `Network Link Conditioner` to restrict bandwidth to a very low level, this callback reports identical values for `totalBytesSent` and `totalBytesExpectedToSend` right at the start of the request, indicating 100% upload progress. However, through network traffic inspection, I observed that the upload continues slowly and is far from complete.

Additionally, I noticed that even though the upload is still ongoing, the request times out after the duration specified in `- NSURLSessionConfiguration.timeoutIntervalForRequest`. According to the documentation:

> "The request timeout interval controls how long (in seconds) a task should wait for additional data to arrive before giving up. The timer associated with this value is reset whenever new data arrives."

This behavior suggests that the timeout timer is not reset as the document says during slow uploads, likely because `didSendBodyData` is not updating as expected. 

Consequently, the timer expires prematurely, causing 1MB chunks to frequently timeout under slow network conditions. This also prevents me from accurately calculating the real-time upload speed, making it impossible to implement my CDN switching strategy.

# Some Investigation
I have found discussions on this forum regarding similar issues. Apple engineers mentioned that upload progress is reported based on the size of data written to the local buffer rather than the actual amount of data transmitted over the network. This can indeed explain the behaviour mentioned above:

- https://developer.apple.com/forums/thread/63548
- https://developer.apple.com/forums/thread/746523

Interestingly, I also noticed that progress reporting works correctly when uploading to some certain servers, which I suspect is related to the TCP receive window size configured on those servers. For example:

- Accurate progress: https://www.w3schools.com
- Inaccurate progress: Most servers, like https://developer.apple.com

I created a sample project to demostrate the progress & timeout issues and different behaviours when uploading to some servers:

- https://github.com/Naituw/NSURLSessionUploadProgressTest

# Questions
- Is there any way to resolve or workaround this issue? 
  - Like adjusting the size of the local send buffer? 
  - or configuring NSURLSession to report progress based on acknowledged TCP packets instead of buffer writes?

- Or are there any alternative solutions for implementing more accurate timeout mechanisms and monitoring real-time upload speed?
