import requests
import json
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# --- Configuration ---
AAP_HOST = "https://your-aap-host"
AAP_TOKEN = "your-pat-token"  # Personal Access Token from AAP UI
VERIFY_SSL = False  # Set to True or path to CA bundle in production

HEADERS = {
    "Authorization": f"Bearer {AAP_TOKEN}",
    "Content-Type": "application/json"
}

# --- Credential Type Payload ---
CREDENTIAL_TYPE_PAYLOAD = {
    "name": "AWS SQS EDA",
    "description": "Custom credential type for EDA aws_sqs_queue source plugin",
    "kind": "cloud",
    "inputs": {
        "fields": [
            {
                "id": "aws_access_key_id",
                "type": "string",
                "label": "AWS Access Key ID"
            },
            {
                "id": "aws_secret_access_key",
                "type": "string",
                "label": "AWS Secret Access Key",
                "secret": True
            },
            {
                "id": "aws_region",
                "type": "string",
                "label": "AWS Region"
            }
        ],
        "required": ["aws_access_key_id", "aws_secret_access_key", "aws_region"]
    },
    "injectors": {
        "extra_vars": {
            "aws_access_key_id": "{{ aws_access_key_id }}",
            "aws_secret_access_key": "{{ aws_secret_access_key }}",
            "aws_region": "{{ aws_region }}"
        }
    }
}

# --- Credential Instance Payload ---
# Fill these in or pull from environment variables / a vault
CREDENTIAL_PAYLOAD = {
    "name": "AWS SQS EDA - Dev",
    "description": "AWS credentials for EDA SQS rulebook activations",
    "credential_type": None,  # Will be set after credential type is created
    "inputs": {
        "aws_access_key_id": "AKIAIOSFODNN7EXAMPLE",
        "aws_secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
        "aws_region": "us-east-1"
    }
}


def create_credential_type():
    url = f"{AAP_HOST}/api/eda/v1/credential-types/"
    response = requests.post(url, headers=HEADERS, json=CREDENTIAL_TYPE_PAYLOAD, verify=VERIFY_SSL)

    if response.status_code == 201:
        cred_type = response.json()
        print(f"[+] Credential type created: {cred_type['name']} (id: {cred_type['id']})")
        return cred_type["id"]
    elif response.status_code == 400 and "already exists" in response.text:
        print("[~] Credential type already exists, fetching existing...")
        return get_existing_credential_type()
    else:
        print(f"[!] Failed to create credential type: {response.status_code}")
        print(response.text)
        return None


def get_existing_credential_type():
    url = f"{AAP_HOST}/api/eda/v1/credential-types/?name=AWS+SQS+EDA"
    response = requests.get(url, headers=HEADERS, verify=VERIFY_SSL)
    results = response.json().get("results", [])
    if results:
        ct = results[0]
        print(f"[~] Found existing credential type id: {ct['id']}")
        return ct["id"]
    print("[!] Could not find existing credential type")
    return None


def create_credential(credential_type_id):
    CREDENTIAL_PAYLOAD["credential_type"] = credential_type_id
    url = f"{AAP_HOST}/api/eda/v1/credentials/"
    response = requests.post(url, headers=HEADERS, json=CREDENTIAL_PAYLOAD, verify=VERIFY_SSL)

    if response.status_code == 201:
        cred = response.json()
        print(f"[+] Credential created: {cred['name']} (id: {cred['id']})")
        return cred["id"]
    else:
        print(f"[!] Failed to create credential: {response.status_code}")
        print(response.text)
        return None


def list_credential_types():
    url = f"{AAP_HOST}/api/eda/v1/credential-types/"
    response = requests.get(url, headers=HEADERS, verify=VERIFY_SSL)
    results = response.json().get("results", [])
    print("\n--- Credential Types ---")
    for ct in results:
        print(f"  id={ct['id']}  name={ct['name']}  kind={ct['kind']}")


if __name__ == "__main__":
    print(f"Targeting AAP host: {AAP_HOST}\n")

    cred_type_id = create_credential_type()

    if cred_type_id:
        create_credential(cred_type_id)

    list_credential_types()