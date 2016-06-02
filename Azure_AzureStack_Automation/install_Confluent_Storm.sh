#!/bin/bash
# Installs the Confluent Kafka platform and Apache Storm
# Confluent 2.0.1 (not tested with Confluent 3.0.x)
# Storm 0.10.0
# Java xxx

# basic service and API settings
storm_server_path=/usr/local/storm
CONFLUENT_APTKEY_URL=http://packages.confluent.io/deb/2.0/archive.key
CONFLUENT_APTREPO_URL=http://packages.confluent.io/deb/2.0
STORM_TAR_URL=http://www-us.apache.org/dist/storm/apache-storm-0.10.0/apache-storm-0.10.0.tar.gz

#URI variables
CONTENT_TYPE='"Content-Type: application/vnd.kafka.json.v1+json"'
DATA_SET_HEADER='{"records":[{"value":{"Created":"'
DATA_SET_FRONT='"${timestamp}"'
DATA_SET_MIDA='"}}, {"value":{"TemperatureinF":"'
DATA_SET_MIDB='"${temp}"'
DATA_SET_END='"}}, {"value":{"Pressureinmb":"1001.64185"}}]}'
LOCAL_URI='"http://localhost:8082/topics/SensorData"'
TIMESTAMP_FORMAT="'%Y-%m-%dT%T'"

# add and update repos
while ! echo y | apt-add-repository -y ppa:webupd8team/java; do
    sleep 10
    apt-add-repository -y ppa:webupd8team/java
done

while ! echo y | apt-get update; do
    sleep 10
    apt-get update
done

# Install Java8
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections

while ! echo y | apt-get install -y oracle-java8-installer; do
    sleep 10
    apt-get install -y oracle-java8-installer
done

# create user and install folder
#adduser --system --no-create-home --home /srv/minecraft-server $minecraft_user
#addgroup --system $minecraft_group
#mkdir $minecraft_server_path
#cd $minecraft_server_path

# Add Confluent's public key to the apt repository
while ! echo y | wget -qO - $CONFLUENT_APTKEY_URL | sudo apt-key add -; do
    sleep 10
    wget -qO - $CONFLUENT_APTKEY_URL | sudo apt-key add -
done

# Update repository
add-apt-repository "deb http://packages.confluent.io/deb/2.0 stable main"

# Install Confluent 2.11.7
apt-get update && apt-get -y install confluent-platform-2.11.7

# Download and Install Storm 10.x
cd /tmp

while ! echo y | wget $STORM_TAR_URL; do
    sleep 10
    wget $STORM_TAR_URL
done

cd /usr/local

tar -zxvf /tmp/apache-storm-0.10.0.tar.gz

mv ./apache-storm-0.10.0 ./storm

# Edit Storm Configuration files
sed -i -e 's/# storm.zookeeper.servers:/storm.zookeeper.servers:/' -e '/storm.zookeeper.servers:/a\ - "localhost"' $storm_server_path/conf/storm.yaml
sed -i 's/# nimbus.host: "nimbus"/nimbus.host: "localhost"/' $storm_server_path/conf/storm.yaml

# Add local demo script file (sends REST packages to Kafka from localhost)
mkdir /home/Scripts
cd /home/Scripts
touch ./send_Kafka_temp.sh
printf "#!/bin/bash\n\n" >> ./send_Kafka_temp.sh
printf 'timestamp() {date + %s}\n\n' "$TIMESTAMP_FORMAT" >> ./send_Kafka_temp.sh
printf "temp=50\n\n" >> ./send_Kafka_temp.sh
printf "while [ true ]\n" >> ./send_Kafka_temp.sh
printf "do\n" >> ./send_Kafka_temp.sh
printf "\tcurl -X POST -H %s -d '%s''%s''%s''%s''%s' %s\n\n" "$CONTENT_TYPE" "$DATA_SET_HEADER" "$DATA_SET_FRONT" "$DATA_SET_MIDA" "$DATA_SET_MIDB" "$DATA_SET_END" "$LOCAL_URI"  >> ./send_Kafka_temp.sh
printf 'if [ "$temp" = "90" ]\n' >> ./send_Kafka_temp.sh
printf "then\n" >> ./send_Kafka_temp.sh
printf '\ttemp = $[temp=50]\n' >> ./send_Kafka_temp.sh
printf "else\n" >> ./send_Kafka_temp.sh
printf '\ttemp=$[temp + 5]\n' >> ./send_Kafka_temp.sh
printf "fi\n\n" >> ./send_Kafka_temp.sh
printf "sleep 3\n\n" >> ./send_Kafka_temp.sh
printf "done" >> ./send_Kafka_temp.sh
chmod +x ./send_Kafka_temp.sh