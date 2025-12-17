#!/usr/bin/env python3
"""
Generate Jenkins JCasC configuration from applications.conf
This script reads applications.conf and generates the corresponding job definitions
in jenkins_casc.yml
"""

import yaml
import sys
from pathlib import Path


def load_base_config(output_file="jenkins_casc.yml"):
    """Load base config without jobs section."""
    with open(output_file, "r") as f:
        config = yaml.safe_load(f)

    # Remove jobs section if it exists (to prevent duplicates)
    if "jobs" in config:
        del config["jobs"]

    return config


def generate_casc_config(
    applications_file="applications.conf",
    output_file="jenkins_casc.yml",
    jenkinsfile_path="jenkins/Jenkinsfile",
):
    """Generate JCasC configuration from applications list.

    Args:
        applications_file: Path to applications.conf
        output_file: Output jenkins_casc.yml file
        jenkinsfile_path: Path to Jenkinsfile in app repo (default: jenkins/Jenkinsfile)
    """

    # Load base config (without jobs)
    config = load_base_config(output_file)

    # Read applications
    applications = []
    if Path(applications_file).exists():
        with open(applications_file, "r") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#"):
                    applications.append(line)

    if not applications:
        print("⚠ No applications found in applications.conf")
        return
    
    # DEBUG: Temporary return to validate clean config without jobs
    return


    # Generate job definitions
    job_scripts = []
    seen_apps = set()

    for app_config in applications:
        parts = app_config.split("|")
        if len(parts) != 3:
            print(f"✗ Warning: Invalid format in applications.conf: {app_config}")
            print(f"  Expected: application_name|github_owner|github_repo")
            continue

        app_name, github_owner, github_repo = parts
        app_name = app_name.strip()
        github_owner = github_owner.strip()
        github_repo = github_repo.strip()

        # Check for duplicates
        if app_name in seen_apps:
            print(f"✗ Duplicate application: {app_name}")
            continue

        seen_apps.add(app_name)

        job_script = f"""multibranchPipelineJob('{app_name}') {{
  branchSources {{
    github {{
      id('{app_name}')
      scanCredentialsId('github-credentials')
      repoOwner('{github_owner}')
      repository('{github_repo}')
      traits {{
        gitHubBranchDiscovery {{
          strategyId(1)
        }}
        gitHubPullRequestDiscovery {{
          strategyId(1)
        }}
        gitHubNotificationContext()
        cloneOptionTrait {{
          extension {{
            shallow(false)
            noTags(false)
            reference('')
            timeout(10)
          }}
        }}
      }}
    }}
  }}
  factory {{
    workflowBranchProjectFactory {{
      scriptPath('{jenkinsfile_path}')
    }}
  }}
}}"""
        job_scripts.append(job_script)

    # Write config
    with open(output_file, "w") as f:
        # Write main config sections
        yaml.dump(config, f, default_flow_style=False, sort_keys=False)

        # Append jobs section with proper formatting
        if job_scripts:
            f.write("\njobs:\n")
            f.write("  - script: >\n")
            for job_script in job_scripts:
                for line in job_script.split("\n"):
                    if line.strip():
                        f.write(f"      {line}\n")
                    else:
                        f.write("\n")

    print(f"✓ Successfully generated {len(applications)} jobs")
    for app in applications:
        app_name = app.split("|")[0].strip()
        print(f"  ✓ {app_name}")


if __name__ == "__main__":
    try:
        generate_casc_config()
        print("\n✓ Configuration updated. Run: docker-compose restart jenkins")
    except Exception as e:
        print(f"✗ Error: {e}", file=sys.stderr)
        sys.exit(1)
