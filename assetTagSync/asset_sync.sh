#!/bin/bash

# Read username, password, url
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

getComputerID() {
    read -p "Please input computer serial number: " serialNum

    response=$(curl -s -H "Authorization: Bearer ${bearerToken}" --request GET \
     --url $url'/api/v1/computers-inventory?section=GENERAL&page=0&page-size=1&filter=hardware.serialNumber%3D%3D%22'$serialNum'%22' \
     --header 'accept: application/json'
    )
    numOfValues=$(echo "$response" | sed -n 's/.*"totalCount" : \(.*\),.*/\1/p')
    currentAssetTag=$(echo "$response" | sed -n 's/.*"assetTag" : "\(.*\)",.*/\1/p')

    if [[ "$numOfValues" != "1" ]]; then
        echo "Incorrect number of Devices with this serial number found. ($numOfValues Found)"
        echo "Operation cancelled"
        exit
    fi
    if [[ $currentAssetTag ]]; then
        echo "This account already has an asset tag: '$currentAssetTag'"
        read -p "Would you like to proceed? [y/n]: " continueVal
        if [[ $continueVal != 'y' ]]; then
            echo "Operation cancelled"
            exit
        fi
    fi

    computerID=$(echo "$response" | sed -n 's/.*"id" : "\(.*\)".*/\1/p')
    computerID=$(echo $computerID | cut -d ' ' -f1) 

}

updateAssetID() {
    read -p "Please scan asset tag: " assetTagVal

    response=$(curl -s -H "Authorization: Bearer ${bearerToken}" --request PATCH \
     --url $url/api/v1/computers-inventory-detail/$computerID \
     --header 'accept: application/json' \
     --header 'content-type: application/json' \
     --data '
    {
        "general": {
            "assetTag": "'$assetTagVal'"
        }
    }
    ')

    if echo "$response" | grep -q '"httpStatus" : 4'; then
        echo 'Failed to update computer.'
        echo "Response:    $response"
        echo "Computer ID: $computerID"
        exit
    else
        echo 'Asset Tag has been successfully updated.'
    fi
    
}


checkTokenExpiration

getComputerID

updateAssetID

