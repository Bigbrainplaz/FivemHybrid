window.addEventListener("message", function (event) {
    const data = event.data;
    const container = document.getElementById("battery-container");

    if (data.type === "showUI") {
        container.style.display = "flex";
        setTimeout(() => {
            container.classList.add("visible");
        }, 10);
    }

    if (data.type === "hideUI") {
        container.classList.remove("visible");
        setTimeout(() => {
            container.style.display = "none";
        }, 500);
    }

    if (data.type === "updateBattery") {
        const fill = document.getElementById("battery-fill");
        const percentage = document.getElementById("hybrid-indicator");
        const level = Math.floor(data.level);
        
        percentage.textContent = `${level}%`;
        
        fill.style.width = `${level}%`;
        
        if (level > 60) {
            fill.style.background = "linear-gradient(90deg, #4CAF50, #8BC34A)";
        } else if (level > 30) {
            fill.style.background = "linear-gradient(90deg, #FFC107, #FF9800)";
        } else {
            fill.style.background = "linear-gradient(90deg, #F44336, #FF5722)";
        }

        if (data.hybrid) {
            container.classList.add("hybrid-active");
        } else {
            container.classList.remove("hybrid-active");
        }
    }
});
