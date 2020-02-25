#!/usr/bin/env python3

# cdk: 1.25.0
from aws_cdk import (
    aws_ec2,
    aws_ecs,
    aws_ecs_patterns,
    aws_servicediscovery,
    core,
)

from os import getenv


class FrontendService(core.Stack):
    
    def __init__(self, scope: core.Stack, id: str, **kwargs):
        super().__init__(scope, id, **kwargs)

        # The base platform stack is where the VPC was created, so all we need is the name to do a lookup and import it into this stack for use
        self.vpc = aws_ec2.Vpc.from_lookup(
            self, "ECSWorkshopVPC",
            vpc_name='ecsworkshop-base/BaseVPC'
        )
        
        self.sd_namespace = aws_servicediscovery.PrivateDnsNamespace.from_private_dns_namespace_attributes(
            self, "SDNamespace",
            namespace_name='service'
        )

        #self.fargate_load_balanced_service = aws_ecs_patterns.ApplicationLoadBalancedFargateService(
        #    self, "FrontendFargateLBService",
        #    vpc=self.vpc,
        #    image=aws_ecs.ContainerImage.from_registry("brentley/ecsdemo-frontend"),
        #    container_port=3000,
        #    cpu=256,
        #    memory_limit_mib=512,
        #    enable_logging=True,
        #    desired_count=1,
        #    public_load_balancer=True,
        #    environment={
        #        "CRYSTAL_URL": "http://ecsdemo-crystal.service:3000/crystal",
        #        "NODEJS_URL": "http://ecsdemo-nodejs.service:3000"
        #    },
        #    cloud_map_options=
        #)
#
#
        ## There has to be a better way, but for now this is what we got.
        ## Allow inbound 3000 from Frontend Service to Backend
        #self.sec_grp_ingress_backend_to_frontend_3000 = aws_ec2.CfnSecurityGroupIngress(
        #    self, "InboundBackendSecGrp3000",
        #    ip_protocol='TCP',
        #    source_security_group_id=self.fargate_load_balanced_service.service.connections.security_groups[0].security_group_id,
        #    from_port=3000,
        #    to_port=3000,
        #    group_id=self.services_3000_sec_group.security_group_id
        #)
#
        ## There has to be a better way, but for now this is what we got.
        ## Allow inbound 3000 Backend to Frontend Service
        #self.sec_grp_ingress_frontend_to_backend_3000 = aws_ec2.CfnSecurityGroupIngress(
        #    self, "InboundFrontendtoBackendSecGrp3000",
        #    ip_protocol='TCP',
        #    source_security_group_id=self.services_3000_sec_group.security_group_id,
        #    from_port=3000,
        #    to_port=3000,
        #    group_id=self.fargate_load_balanced_service.service.connections.security_groups[0].security_group_id,
        #)        


_env = core.Environment(account=getenv('AWS_ACCOUNT_ID'), region=getenv('AWS_DEFAULT_REGION'))
stack_name = "ecsworkshop-frontend"
app = core.App()
FrontendService(app, stack_name, env=_env)
app.synth()
