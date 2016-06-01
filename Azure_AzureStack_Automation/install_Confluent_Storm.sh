#!/bin/bash
# Installs the Confluent Kafka platform and Apache Storm
# Confluent 2.0.1 (not tested with Confluent 3.0.x)
# Storm 0.10.0
# Java xxx

# basic service and API settings
storm_server_path=/usr/local/storm
#minecraft_user=minecraft
#minecraft_group=minecraft
#UUID_URL=https://api.mojang.com/users/profiles/minecraft/$1
#server_jar=minecraft_server.$2.jar
#SERVER_JAR_URL=https://s3.amazonaws.com/Minecraft.Download/versions/$2/minecraft_server.$2.jar
CONFLUENT_APTKEY_URL=http://packages.confluent.io/deb/2.0/archive.key
CONFLUENT_APTREPO_URL=http://packages.confluent.io/deb/2.0
STORM_TAR_URL=http://www-us.apache.org/dist/storm/apache-storm-0.10.0/apache-storm-0.10.0.tar.gz

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
mkdir $HOME/Scripts
cd $$HOME/Scripts
touch ./send_Kafka_temp.sh
printf "#!/bin/bash\n" >> ./send_Kafka_temp.sh
printf "timestamp() {date +'%Y-%m-%dT%T'}\n" >> ./send_Kafka_temp.sh
printf "temp=50\n" >> ./send_Kafka_temp.sh
printf "while [ true ]\n" >> ./send_Kafka_temp.sh
printf "do\n" >> ./send_Kafka_temp.sh
printf "curl -X POST -H" & " Content-Type: application/vnd.kafka.json.v1+json" "-d" '{"records":[{"value":{"Created":"'"$(timestamp)"'"}}, {"value":{"TemperatureinF":"'"${temp}"'"}}, {"value":{"Pressureinmb":"1001.64185"}}]}' "http://ecgcat-iot1.corp.microsoft.com:8082/topics/SensorData" >> ./send_Kafka_temp.sh
printf "[ ""$temp"" = ""90"" ]\n" >> ./send_Kafka_temp.sh
printf "then\n" >> ./send_Kafka_temp.sh
printf "temp = $[temp=50]\n" >> ./send_Kafka_temp.sh
printf "else" >> ./send_Kafka_temp.sh
printf "temp=$[temp + 5]\n" >> ./send_Kafka_temp.sh
printf "fi" >> ./send_Kafka_temp.sh
printf "sleep 3" >> ./send_Kafka_temp.sh
printf "done" >> ./send_Kafka_temp.sh
chmod +x ./send_Kafka_temp.sh