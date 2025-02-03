
const sourceAddress = localStorage.getItem('source-add');
const serverAddress = localStorage.getItem('server-add');
let currentSourceurl = '192.168.1.134';
let currentServerUrl = '127.0.0.1:8000';

document.getElementById('file-upload').addEventListener('change', function (event) {
    const liveText = document.getElementById('live-stream-text');
    liveText.style.opacity = '0%';
    const fileInput = event.target;
    const file = fileInput.files[0];

    if (file) {
        const reader = new FileReader();
        reader.onload = function (e) {
            const imagePreview = document.getElementById('image-preview');
            imagePreview.style.minWidth = '250px';
            imagePreview.src = e.target.result;
            imagePreview.style.display = 'block';

        };
        reader.readAsDataURL(file);
    }
});




//for image
document.getElementById('get-status-btn').addEventListener('click', function () {
    const liveText = document.getElementById('live-stream-text');
    liveText.style.opacity = '0%';
    console.log('trying to fecth.................');
    if (sourceAddress) {
        currentSourceurl = sourceAddress
    }
    //  fetch('http://192.168.1.134/capture')  
    fetch(`http://${currentSourceurl}/capture`)
        .then(response => response.blob())
        .then(blob => {
            console.log("fetching...........", blob);
            const imagePreview = document.getElementById('image-preview');
            imagePreview.style.minWidth = '250px';
            const fileInput = document.getElementById('file-upload');

            const imageFile = new File([blob], 'status-image.jpg', { type: blob.type });

            const dataTransfer = new DataTransfer();
            dataTransfer.items.add(imageFile);
            fileInput.files = dataTransfer.files;

            const reader = new FileReader();
            reader.onload = function (e) {

                imagePreview.src = e.target.result;
                imagePreview.style.display = 'block';
            };
            reader.readAsDataURL(imageFile);
        })
        .catch(error => {
            console.error('Error fetching image:', error);
            alert('An error occurred while fetching the image.');
        });
});

//for livestream
document.getElementById('get-monitor-btn').addEventListener('click', function () {
    console.log('trying to fetch video.................');

    const imagePreview = document.getElementById('image-preview');
    const videoStreamUrl = `http://${currentSourceurl}:81/stream`;
    const liveText = document.getElementById('live-stream-text');
    liveText.style.opacity = '100%';

    // Directly assign the URL to the image src
    imagePreview.src = videoStreamUrl;
    imagePreview.style.display = 'block';
    imagePreview.style.minWidth = '800px';// Ensure the image is visible
});





document.getElementById('upload-form').addEventListener('submit', function (event) {
    event.preventDefault();
    const liveText = document.getElementById('live-stream-text');
    liveText.style.opacity = '0%';
    const fileInput = document.getElementById('file-upload');
    const file = fileInput.files[0];

    if (file) {
        const formData = new FormData();
        formData.append('file', file);

        // Show loading indicator
        const diseaseName = document.getElementById('disease-name');
        const loadingSpinner = document.getElementById('loading-spinner');
        diseaseName.textContent = '';
        diseaseName.style.display = 'none';
        loadingSpinner.style.display = 'block';

        if (serverAddress) {
            currentServerUrl = serverAddress
        }

        fetch(`http://${currentServerUrl}/detect`, {
            method: 'POST',
            body: formData
        })
            .then(response => response.json())
            .then(data => {
                setTimeout(function () {
                    loadingSpinner.style.display = 'none';
                    displayPrediction(data.prediction);
                }, 2500);
            })
            .catch(error => {
                console.error('Error:', error);
                loadingSpinner.style.display = 'none';
                diseaseName.style.display = 'block';
                diseaseName.textContent = 'An error occurred while processing the prediction.';
            });
    } else {
        alert('Please select an image file first.');
    }
});

function displayPrediction(prediction) {
    const diseaseName = document.getElementById('disease-name');
    const resultSheet = document.getElementById('result-sheet');
    const sheetDiseaseName = document.getElementById('sheet-disease-name');
    const sheetSeverity = document.getElementById('sheet-severity');
    const sheetHarmfulness = document.getElementById('sheet-harmfulness');
    const sheetTreatment = document.getElementById('sheet-treatment');
    const sheetPesticide = document.getElementById('sheet-pesticide');
    const sheetPreventionList = document.getElementById('sheet-prevention-list');

    // Display main disease name on the page
    diseaseName.textContent = `Disease: ${prediction.name}`;
    diseaseName.style.display = 'block';

    // Set the content in the result sheet
    sheetDiseaseName.textContent = prediction.name;
    sheetSeverity.innerHTML = `<strong>Severity:</strong> ${prediction.severity}`;
    sheetHarmfulness.innerHTML = `<strong>Harmfulness:</strong> ${prediction.harmfulness}`;
    sheetTreatment.innerHTML = `<strong>Treatment:</strong> ${prediction.treatment}`;
    if (Array.isArray(prediction.pesticide)) {
        sheetPesticide.innerHTML = `<strong>Pesticide:</strong> ${prediction.pesticide.join(', ')}`;
    } else {
        sheetPesticide.innerHTML = `<strong>Pesticide:</strong> ${prediction.pesticide}`;
    }

    sheetPreventionList.innerHTML = '';
    prediction.prevention.forEach(item => {
        const listItem = document.createElement('li');
        listItem.textContent = item;
        sheetPreventionList.appendChild(listItem);
    });

    resultSheet.classList.add('open');
}

// Toggle result sheet by clicking on disease name
document.getElementById('result-sheet').addEventListener('dblclick', function () {
    const resultSheet = document.getElementById('result-sheet');
    resultSheet.classList.toggle('open');
});
document.getElementById('disease-name').addEventListener('click', function () {
    const resultSheet = document.getElementById('result-sheet');
    resultSheet.classList.toggle('open');
});

// Close button functionality
document.getElementById('close-btn').addEventListener('click', function () {
    const resultSheet = document.getElementById('result-sheet');
    resultSheet.classList.remove('open');
});