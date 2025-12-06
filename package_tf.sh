#!/bin/bash

rm oke-langfuse.zip
zip -rxvf oke-langfuse.zip ./* -x .terraform/**/* -x .github/**/* -x *.tfvars -x *.zip -x *.locl.hcl
