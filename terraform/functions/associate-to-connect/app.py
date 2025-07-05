"""
Create integration associations between Connect and Q in Connect instance.
This is not currently supported by Cloud Control, so needs to happen manually.

If you have been experimenting with click-ops you may have left over integrations, 
this attempts to clean this up as well
"""
import logging

import boto3
import botocore

# Initialize global variables
logger = logging.getLogger()
logger.setLevel("INFO")
CONNECT_CLIENT = boto3.client('connect')

def lambda_handler(event, context):
    instance_id = event.get('instance_id')
    wisdom_arn = event.get('wisdom_arn')
    kb_arn = event.get('kb_arn')

    logger.info("Creating Integration Association between Connect Instance: %s and the QConnect Wisdom %s and KB %s", instance_id, wisdom_arn, kb_arn)
    try:
        # Check Wisdom Type
        wisdom_type = "WISDOM_ASSISTANT"
        response = CONNECT_CLIENT.list_integration_associations(InstanceId=instance_id, IntegrationType=wisdom_type)
        integrations_list = response["IntegrationAssociationSummaryList"] if "IntegrationAssociationSummaryList" in response else []
        skip_link = False
        if len(integrations_list) > 0:
            for entry in integrations_list:
                if entry["IntegrationArn"] == wisdom_arn:
                    skip_link = True
                else:
                    CONNECT_CLIENT.delete_integration_association(
                        InstanceId=instance_id, 
                        IntegrationAssociationId=entry["IntegrationAssociationId"]
                    )
        # We skip on existing
        if not skip_link:
            CONNECT_CLIENT.create_integration_association(
                InstanceId=instance_id, 
                IntegrationArn=wisdom_arn, 
                IntegrationType=wisdom_type
            )
        
         # Check Wisdom Type
        kb_type = "WISDOM_KNOWLEDGE_BASE"
        response = CONNECT_CLIENT.list_integration_associations(InstanceId=instance_id, IntegrationType=kb_type)
        kb_list = response["IntegrationAssociationSummaryList"] if "IntegrationAssociationSummaryList" in response else []
        skip_link = False
        if len(kb_list) > 0:
            for item in kb_list:
                if item["IntegrationArn"] == kb_arn:
                    skip_link = True
                else:
                    CONNECT_CLIENT.delete_integration_association(
                        InstanceId=instance_id, 
                        IntegrationAssociationId=item["IntegrationAssociationId"]
                    )
        if not skip_link:
            CONNECT_CLIENT.create_integration_association(
                InstanceId=instance_id, 
                IntegrationArn=kb_arn, 
                IntegrationType=kb_type
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
