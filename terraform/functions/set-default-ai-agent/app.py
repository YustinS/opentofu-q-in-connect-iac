"""
Set the default agent for Connect to use.
This can be achieved in the console, but if automation should have 
all components deployed and activated this may be of use
"""
import logging

import boto3
import botocore

# Initialize global variables
logger = logging.getLogger()
logger.setLevel("INFO")
Q_CONNECT_CLIENT = boto3.client('qconnect')

def lambda_handler(event, context):
    assistant_id = event.get('assistant_id')
    agent_type= event.get('agent_type')
    configuration = event.get('configuration')

    logger.info("Attempting to update assistant %s, type of %s, to configuration %s", assistant_id, agent_type, configuration)
    try:
        Q_CONNECT_CLIENT.update_assistant_ai_agent(
            assistantId=assistant_id,
            aiAgentType=agent_type,
            configuration=configuration
        )
        # Return generic response on success
        response = {
            "status": "SUCCESS"
        }
        return response
    except botocore.exceptions.ClientError as e:
        logger.error("Client Error: %s", e)
        return {'status': "CLIENT_ERROR", 'Message': str(e)}
    except Exception as e:
        logger.error("Exception: %s", e)
        return {'status': "EXCEPTION", 'Message': str(e)}
