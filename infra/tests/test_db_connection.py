from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from sqlalchemy import create_engine, text
from sqlalchemy.engine import make_url

# Azure Key Vault setup
KEYVAULT_NAME = "bullpen-blog-keyvault"
KV_URI = f"https://{KEYVAULT_NAME}.vault.azure.net/"

credential = DefaultAzureCredential()  # will use env vars, managed identity, or logged-in az CLI
client = SecretClient(vault_url=KV_URI, credential=credential)

# Fetch the secret
secret_name = "ProdDatabaseURI"
prod_db_uri = client.get_secret(secret_name).value
url = make_url(prod_db_uri)

engine = create_engine(url)
with engine.connect() as conn:
    result = conn.execute(text("SELECT 1"))
    print(result.scalar())
