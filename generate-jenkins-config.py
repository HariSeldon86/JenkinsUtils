#!/usr/bin/env python3
"""
Generate Jenkins JCasC configuration from applications.yaml
This script reads applications.yaml and generates the corresponding job definitions
in jenkins_casc.yml
"""

import yaml
import sys
from pathlib import Path


def load_base_config(output_file="jenkins_casc.yml"):
    """Load base config without jobs section."""
    if not Path(output_file).exists():
        return {"jenkins": {}, "unclassified": {}, "credentials": {}}
        
    with open(output_file, "r") as f:
        config = yaml.safe_load(f)

    # Remove jobs section if it exists (to prevent duplicates)
    if config and "jobs" in config:
        del config["jobs"]

    return config


def generate_casc_config(
    applications_file="applications.yaml",
    output_file="jenkins_casc.yml",
):
    """Generate JCasC configuration from applications list.

    Args:
        applications_file: Path to applications.yaml
        output_file: Output jenkins_casc.yml file
    """

    # Load base config (without jobs)
    config = load_base_config(output_file)

    # Read applications
    if not Path(applications_file).exists():
        print(f"✗ Error: {applications_file} not found")
        return

    with open(applications_file, "r") as f:
        data = yaml.safe_load(f)
        applications = data.get("applications", [])

    if not applications:
        print(f"⚠ No applications found in {applications_file}")
        return

    # Generate job definitions
    job_scripts = []
    seen_apps = set()

    MULTIBRANCH_TEMPLATE = """multibranchPipelineJob('{name}') {{
  branchSources {{
    git {{
      id('{name}')
      remote('https://github.com/{owner}/{repo}.git')
      credentialsId('github-credentials')
      includes('*')
    }}
  }}
  factory {{
    workflowBranchProjectFactory {{
      scriptPath('{scriptPath}')
    }}
  }}
  orphanedItemStrategy {{
    discardOldItems {{
      numToKeep(10)
    }}
  }}
}}"""

    SINGLE_BRANCH_TEMPLATE = """pipelineJob('{name}') {{
  definition {{
    cpsScm {{
      scm {{
        git {{
          remote {{
            url('https://github.com/{owner}/{repo}.git')
            credentials('github-credentials')
          }}
          branches('{branch}')
        }}
      }}
      scriptPath('{scriptPath}')
    }}
  }}
}}"""

    for app in applications:
        app_name = app.get("name")
        owner = app.get("owner")
        repo = app.get("repo")
        app_type = app.get("type", "multibranch")
        script_path = app.get("scriptPath", "jenkins/Jenkinsfile")
        branch = app.get("branch", "main")

        if not all([app_name, owner, repo]):
            print(f"✗ Warning: Missing required fields for {app_name or 'unknown app'}")
            continue

        # Check for duplicates
        if app_name in seen_apps:
            print(f"✗ Duplicate application: {app_name}")
            continue

        seen_apps.add(app_name)

        if app_type == "multibranch":
            job_script = MULTIBRANCH_TEMPLATE.format(
                name=app_name, owner=owner, repo=repo, scriptPath=script_path
            )
        elif app_type == "single":
            job_script = SINGLE_BRANCH_TEMPLATE.format(
                name=app_name, owner=owner, repo=repo, scriptPath=script_path, branch=branch
            )
        else:
            print(f"✗ Warning: Unknown type '{app_type}' for {app_name}")
            continue

        job_scripts.append(job_script)

    # Write config
    with open(output_file, "w") as f:
        # Write main config sections
        if config:
            yaml.dump(config, f, default_flow_style=False, sort_keys=False)

        # Append jobs section with proper formatting
        if job_scripts:
            # Add a separator if config was written
            if config:
                f.write("\n")
            f.write("jobs:\n")
            f.write("  - script: >\n")
            for i, job_script in enumerate(job_scripts):
                for line in job_script.split("\n"):
                    if line.strip():
                        f.write(f"      {line}\n")
                    else:
                        f.write("\n")
                # Add newline between jobs for readability in the script string
                if i < len(job_scripts) - 1:
                    f.write("\n")

    print(f"✓ Successfully generated {len(job_scripts)} jobs")
    for app_name in seen_apps:
        print(f"  ✓ {app_name}")


if __name__ == "__main__":
    try:
        generate_casc_config()
        print("\n✓ Configuration updated. Run: docker-compose restart jenkins")
    except Exception as e:
        print(f"✗ Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)
