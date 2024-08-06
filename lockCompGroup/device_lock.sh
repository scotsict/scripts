#!/bin/bash

# Read username, password, url, groupID, lock_passcode
source creds.config

bearerToken=""
tokenExpirationEpoch=""

getBearerToken() {
	response=$(curl -s -u "$username":"$password" "$url"/api/v1/auth/token -X POST)
	bearerToken=$(echo "$response" | plutil -extract token raw -)
	tokenExpiration=$(echo "$response" | plutil -extract expires raw - | awk -F . '{print $1}')
	tokenExpirationEpoch=$(date -j -f "%Y-%m-%dT%T" "$tokenExpiration" +"%s")
}

checkTokenExpiration() {
    nowEpochUTC=$(date -j -f "%Y-%m-%dT%T" "$(date -u +"%Y-%m-%dT%T")" +"%s")
    if [[ tokenExpirationEpoch -gt nowEpochUTC ]]
    then
        true
    else
        getBearerToken
    fi
}

invalidateToken() {
	responseCode=$(curl -w "%{http_code}" -H "Authorization: Bearer ${bearerToken}" $url/api/v1/auth/invalidate-token -X POST -s -o /dev/null)
	if [[ ${responseCode} == 204 ]]
	then
		bearerToken=""
		tokenExpirationEpoch="0"
	elif [[ ${responseCode} == 401 ]]
	then
        true
	else
		echo "An unknown error occurred invalidating the token"
        exit
	fi
}

getComputersFromGroup() {
    #Query smart group 

    # response=$(curl -s -H "Authorization: Bearer ${bearerToken}" --request POST \
    #     --url $url/api/v1/smart-computer-groups/377/recalculate \
    #     --header 'accept: application/json'
    # )

    response=$(curl -s -H "Authorization: Bearer ${bearerToken}" --request GET \
        --url $url/JSSResource/computergroups/id/377 \
        --header 'accept: application/xml'
    )

    # Extension attribute stuff
    # response=$(curl -s -H "Authorization: Bearer ${bearerToken}" curl --request GET \
    #  --url $url/JSSResource/computerextensionattributes/id/48 \
    #  --header 'accept: application/json'
    # )

    # echo $response
    # response=$(echo $response | xmllint --format -)
    # echo $response | xmllint --format -
    # echo $response
    # echo "\n\n\n"
    extracted_ids=$(echo $response | xmllint --xpath "//computer_group/computers/computer/id/text()" -)
    # xmllint --xpath "//computers/text()" "$response"


    for id in $extracted_ids; do
        sendLockCommand $id
    done

    # curl -s -H "Authorization: Bearer ${bearerToken}" --request POST \
    #     --url $url/JSSResource/computercommands/command/DeviceLock/passcode/102938/id/11747

}


sendLockCommand() {
    # echo $1
    # echo $url/JSSResource/computercommands/command/DeviceLock/passcode/$lock_passcode/id/$1
    echo $1


    # curl -s -H "Authorization: Bearer ${bearerToken}" --request POST \
    #     --url $url/JSSResource/computercommands/command/DeviceLock/passcode/$lock_passcode/id/$1
    # curl -s -H "Authorization: Bearer ${bearerToken}" --request POST \
    #     --url $url/JSSResource/computercommands/command/DeviceLock/passcode/102938/id/11747


    # 1c299c46-6d76-483b-b2c9-1c8f38ced2c0
    # curl -s -H "Authorization: Bearer ${bearerToken}" --request GET \
    #  --url $url/JSSResource/computercommands/uuid/1c299c46-6d76-483b-b2c9-1c8f38ced2c0 \
    #  --header 'accept: application/json'


    # curl -s -H "Authorization: Bearer ${bearerToken}" --request GET \
    #  --url $url/JSSResource/computercommands \
    #  --header 'accept: application/json'







    # read -p "Please scan asset tag: " assetTagVal

    # response=$(curl -s -H "Authorization: Bearer ${bearerToken}" --request PATCH \
    #  --url $url/api/v1/computers-inventory-detail/$computerID \
    #  --header 'accept: application/json' \
    #  --header 'content-type: application/json' \
    #  --data '
    # {
    #     "general": {
    #         "assetTag": "'$assetTagVal'"
    #     }
    # }
    # ')

    # if echo "$response" | grep -q '"httpStatus" : 4'; then
    #     echo 'Failed to update computer.'
    #     echo "Response:    $response"
    #     echo "Computer ID: $computerID"
    #     exit
    # else
    #     echo 'Asset Tag has been successfully updated.'
    # fi
    
}


checkTokenExpiration


getComputersFromGroup


# sendLockCommand



# # Define the XML content as a variable
# xml_content='<person>
#   <name>John Doe</name>
#   <age>30</age>
#   <email>john.doe@example.com</email>
# </person>'

# # Format the XML content from the variable
# echo "Formatted XML content from variable:"
# echo "$xml_content" | xmllint --format -

# # Define the XPath query as a variable
# xpath_query='//name/text()'

# # Extract data using XPath from the variable
# echo "Extracted name from XML content:"
# echo "$xml_content" | xmllint --xpath "$xpath_query" -