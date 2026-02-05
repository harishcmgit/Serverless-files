import runpod

def handler(job):
    """
    This function is called automatically by RunPod
    whenever a request is sent to your endpoint.
    """

    # job["input"] contains whatever you send from send_request.py
    input_data = job.get("input", {})

    print("✅ Job received:", input_data)

    # Simple test response
    return {
        "status": "success",
        "message": "Serverless handler is working correctly",
        "received_input": input_data
    }

# Start the RunPod serverless worker
runpod.serverless.start({
    "handler": handler
})