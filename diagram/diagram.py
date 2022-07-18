# diagram.py
from diagrams import Cluster, Diagram
from diagrams.gcp.security import KMS
from diagrams.gcp.compute import GCE
from diagrams.onprem.security import Vault
from diagrams.generic.os import Ubuntu

with Diagram("Main Diagram", show=True):
    with Cluster("Cloud Key Management Service"):
        with Cluster("Keyring [test]"):
            kms1 = [ KMS("KEY [vault-test1]")] 

    with Cluster("Ubuntu Linux Server"):
        with Cluster("Google Computer [vault-node1]"):
            os1 = GCE("") 
            vault1 = Vault("Vault Server [vault]")

        kms1 >> os1
        os1 - vault1

