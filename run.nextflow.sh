#!/bin/bash
adjectives="admiring adoring affectionate agitated amazing angry awesome beautiful blissful bold boring brave busy charming clever cool compassionate competent condescending confident cranky crazy dazzling determined distracted dreamy eager ecstatic elastic elated elegant eloquent epic exciting fervent festive flamboyant focused friendly frosty funny gallant gifted goofy gracious great happy hardcore heuristic hopeful hungry infallible inspiring interesting intelligent jolly jovial keen kind laughing loving lucid magical mystifying modest musing naughty nervous nice nifty nostalgic objective optimistic peaceful pedantic pensive practical priceless quirky quizzical recursing relaxed reverent romantic sad serene sharp silly sleepy stoic strange stupefied suspicious sweet tender thirsty trusting unruffled upbeat vibrant vigilant vigorous wizardly wonderful xenodochial youthful zealous zen"

nouns="albattani allen almeida antonelli agnesi archimedes ardinghelli aryabhata austin babbage banach banzai bardeen bartik bassi beaver bell benz bhabha bhaskara black blackburn blackwell bohr booth borg bose bouman boyd brahmagupta brattain brown carson cauchy chandrasekhar chaplygin chatelet chatterjee chebyshev cohen chaum clarke colden cori cray curran curie darwin davinci dewdney dhawan diffie dijkstra dirac driscoll dubinsky easley edison einstein elgamal elion ellis engelbart euclid euler faraday feathers feistel fermat fermi feynman franklin gagarin galileo galois ganguly gates gauss germain goldberg goldstine goldwasser golick goodall gould greider grothendieck haibt hamilton haslett hawking hellman heisenberg hermann herschel hertz heyrovsky hodgkin hofstadter hoover hopper hugle hypatia ishizaka jackson jang jennings jepsen johnson joliot jones kalam kapitsa kare keldysh keller kepler khayyam khorana kilby kirch knuth kowalevski lalande lamarr lamport leakey leavitt lederberg lehmann lewin lichterman liskov lovelace lumiere mahavira margulis matsumoto maxwell mayer mccarthy mcclintock mclaren mclean mcnulty meitner meninsky merkle mestorf mirzakhani moore morse murdock moser napier nash neumann newton nightingale nobel noether northcutt noyce panini pare pasteur payne perlman pike poincare poitras proskuriakova ptolemy raman ramanujan ride montalcini ritchie rhodes robinson roentgen rosalind rubin saha sammet sanderson satoshi shamir shannon shaw shirley shockley shtern sinoussi snyder solomon spence stonebraker sutherland swanson swartz swirles taussig tereshkova tesla tharp thompson torvalds tu turing varahamihira vaughan visvesvaraya volhard villani wescoff wiles williams wilson wing wozniak wright wu yalow yonath zhukovsky"

random_element() {
    echo "$1" | tr ' ' '\n' | sort -R | head -n 1
}

RANDOM_SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
GENERATED_UID=$(uuidgen)
RESOURCE_VERSION=$((RANDOM % 1000000))
CURRENT_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
NF_RUN_NAME="$(random_element "$adjectives")-$(random_element "$nouns")"

# Đọc template YAML và thay thế các biến
sed -e "s/\${RANDOM_SUFFIX}/$RANDOM_SUFFIX/g" \
    -e "s/\${GENERATED_UID}/$GENERATED_UID/g" \
    -e "s/\${RESOURCE_VERSION}/$RESOURCE_VERSION/g" \
    -e "s/\${CURRENT_TIMESTAMP}/$CURRENT_TIMESTAMP/g" \
    configmap.template.yml > nf-configmap.yml

# Áp dụng ConfigMap
kubectl apply -f nf-configmap.yml



sed -e "s/\${NF_RUN_NAME}/$NF_RUN_NAME/g" \
    -e "s/nf-config-\${RANDOM_SUFFIX}/nf-config-$RANDOM_SUFFIX/g" \
    nf.driver.template.yml > nextflow.driver.yml


kubectl apply -f nextflow.driver.yml


# Set the pod name here
POD_NAME=$NF_RUN_NAME

# Set the namespace (leave empty for default namespace)
NAMESPACE=""

# Set the interval between log checks (in seconds)
INTERVAL=5

# Function to check if the pod exists
check_pod_exists() {
    kubectl get pod $NAMESPACE $POD_NAME &> /dev/null
    return $?
}

# Check if namespace is set, and if so, format it for use in kubectl commands
if [ ! -z "$NAMESPACE" ]; then
    NAMESPACE="-n $NAMESPACE"
fi

# Check if the pod exists
if ! check_pod_exists; then
    echo "Pod '$POD_NAME' does not exist or you don't have access to it."
    exit 1
fi

echo "Fetching logs for pod '$POD_NAME' every $INTERVAL seconds..."
echo "Press Ctrl+C to exit."

# Initialize the last log timestamp
LAST_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Continuous loop to fetch new logs
while true; do
    # Fetch new logs since the last check
    NEW_LOGS=$(kubectl logs $NAMESPACE $POD_NAME --since-time=$LAST_TIMESTAMP)
    
    # If there are new logs, print them
    if [ ! -z "$NEW_LOGS" ]; then
        echo "$NEW_LOGS"
        # Update the last timestamp
        LAST_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    fi
    
    # Wait for the specified interval
    sleep $INTERVAL
done

# Handle Ctrl+C
trap 'echo -e "\nStopped monitoring logs."; exit 0' INT