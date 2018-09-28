# Threat Stack Docker Agent, ECS Compatible

[Threat Stack](https://www.threatstack.com) recently added support for a [dockerized agent](https://threatstack.zendesk.com/hc/en-us/articles/360016123992), which is great! Unfortunately,
their [official image](https://hub.docker.com/r/threatstack/ts-docker/) requires you to mount a
configuration file. This works well for some orchestrators, but due not so much with [Amazon's
Elastic Container Service](https://aws.amazon.com/ecs/). This image addresses that issue.

This uses the official image as a base and then applies some very basic templating using environment
variables and `sed` to achieve a more seamless ECS experience. You should consider using a tool such
as [Segment's Chamber](https://github.com/segmentio/chamber) to load your environment variables from
SSM at launch.

## Getting Started

These instructions will guide you through the basics of using this image. While this image was
designed to be used with ECS, you can certainly use it with any other orchestrator.

**IMPORTANT NOTE:** Given the nature of this package (security, lots of permissive access), you are
*highly encouraged* to clone / fork this repository, build the image yourself, and push/pull it from
your own Docker registry.

### Prerequisites

- Docker CE
- An active [Threat Stack](https://www.threatstack.com) account
- A valid Threat Stack deployment key

### Environment Variables

The following environment variables can be passed to the container to make configuration changes.
The only required variable is `THREATSTACK_DEPLOYMENT_KEY`. If it is not present, the container will
not function.

`THREATSTACK_DEPLOY_KEY`: The deployment key generated for your Threat Stack account. Required.
`THREATSTACK_RULESET`: The rulesets you want to use. Defaults to `Base Rule Set, Docker Rule Set`.
`THREATSTACK_LOGLEVEL`: Changes the logging verbosity. Defaults to `info`.

### Running the Container in Docker

If you're not using the container within ECS, you can use the following command to run the
container:

```shell
sudo docker run -it -d \
  -e THREATSTACK_DEPLOY_KEY="<YOUR DEPLOYMENT KEY>" \
  --name=ts-docker \
  --privileged \
  --network=host \
  --pid=host \
  --cap-add=AUDIT_CONTROL \
  --cap-add=AUDIT_READ \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_ADMIN \
  -v /:/threatstackfs/ \
  -v /var/run/docker.sock:/var/run/docker.sock
  DOCKER_IMAGE
```

You will need to replace `DOCKER_IMAGE` with your image.

## Running the Container in ECS

Unfortunately, ECS does not currently support the `--pid=host` Docker parameter, so the agent will
not fully work in ECS. There is currently an [open issue](https://github.com/aws/amazon-ecs-agent/issues/473)
that is requesting support for this. It appears to be a feature that will be added shortly. In the
mean time, here is the basic task definition *without* the `--pid=host` support:

```json
{
  "requiresCompatibilities": [
    "EC2"
  ],
  "containerDefinitions": [
    {
      "name": "threatstack-agent",
      "image": "lever/threatstack:1.8.0c",
      "memoryReservation": "1024",
      "essential": true,
      "portMappings": [],
      "environment": null,
      "mountPoints": [
        {
          "sourceVolume": "system",
          "containerPath": "/threatstackfs",
          "readOnly": ""
        },
        {
          "sourceVolume": "docker",
          "containerPath": "/var/run/docker.sock",
          "readOnly": ""
        }
      ],
      "volumesFrom": null,
      "hostname": null,
      "user": null,
      "workingDirectory": null,
      "privileged": true,
      "extraHosts": null,
      "logConfiguration": null,
      "ulimits": null,
      "linuxParameters": {
        "capabilities": {
            "add": ["AUDIT_CONTROL", "AUDIT_READ", "NET_ADMIN", "SYS_ADMIN"]
          }
        },
      "dockerLabels": null,
      "repositoryCredentials": {
        "credentialsParameter": ""
      }
    }
  ],
  "volumes": [
    {
      "host": {
        "sourcePath": "/"
      },
      "name": "system"
    },
    {
      "host": {
        "sourcePath": "/var/run/docker.sock"
      },
      "name": "docker"
    }
  ],
  "networkMode": "host",
  "memory": null,
  "cpu": null,
  "placementConstraints": [],
  "family": "threatstack",
  "executionRoleArn": null
}
```

## Acknowledgments

Huge thanks to the Threat Stack team for putting forth the inital work to create a Docker-based
agent. More so, a huge thanks for making a fantastic product that has made our lives much easier!
