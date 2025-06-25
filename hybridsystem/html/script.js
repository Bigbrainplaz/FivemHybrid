const container = document.getElementById("battery-container");
const settingsPanel = document.getElementById("settingsPanel");
const focusBanner = document.createElement("div");

let inFocusMode = false;
let isMoving = false;
let offsetX, offsetY;

// === Add FOCUS BANNER ===
focusBanner.id = "focusBanner";
focusBanner.textContent = "IN FOCUS MODE - PRESS ESC TO EXIT";
focusBanner.style.cssText = `
  position: fixed;
  top: 10px;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(255, 255, 0, 0.95);
  color: #000;
  padding: 10px 20px;
  font-size: 18px;
  font-weight: bold;
  border-radius: 10px;
  z-index: 9999;
  display: none;
  pointer-events: none;
`;
document.body.appendChild(focusBanner);

// === FOCUS MODE ===
function enterFocusMode() {
    inFocusMode = true;
    focusBanner.style.display = "block";
    document.body.style.cursor = "default";

    fetch(`https://${GetParentResourceName()}/setNuiFocus`, {
        method: "POST",
        body: JSON.stringify({ focus: true })
    });
}

function exitFocusMode() {
    inFocusMode = false;
    focusBanner.style.display = "none";
    document.body.style.cursor = "none";

    fetch(`https://${GetParentResourceName()}/setNuiFocus`, {
        method: "POST",
        body: JSON.stringify({ focus: false })
    });
}

// === MESSAGE EVENTS ===
window.addEventListener("message", function (event) {
    const data = event.data;

    if (data.type === "showUI") {
        container.style.display = "flex";

        setTimeout(() => {
            container.classList.add("visible");

            let posX = 0.85;
            let posY = 0.85;

            // If position provided from Lua, use it
            if (data.position && typeof data.position.x === "number" && typeof data.position.y === "number") {
                posX = data.position.x;
                posY = data.position.y;
            }

            container.style.position = "absolute";
            container.style.left = `${posX * window.innerWidth}px`;
            container.style.top = `${posY * window.innerHeight}px`;
            container.style.transform = "translate(0%, 0%)";
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

    if (data.type === "setFocus") {
        const gear = document.getElementById("openSettings");
        if (gear) gear.style.display = data.focus ? "block" : "none";
    }

    if (data.type === "enterFocus") {
        enterFocusMode();
    }

    if (data.type === "exitFocus") {
        exitFocusMode();
    }
});

// === ESC TO UNFOCUS ===
document.addEventListener("keydown", function (e) {
    if (e.key === "Escape" && inFocusMode) {
        exitFocusMode();
        fetch(`https://${GetParentResourceName()}/escapePressed`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({})
        });
    }
});

// === SETTINGS LOGIC ===
document.getElementById("openSettings").addEventListener("click", () => {
    settingsPanel.style.display = "flex";
});

document.getElementById("closeSettings").addEventListener("click", () => {
    settingsPanel.style.display = "none";
});

document.getElementById("saveSettings").addEventListener("click", () => {
    const autoShow = document.getElementById("autoShowToggle")?.checked ?? true;

    const rect = container.getBoundingClientRect();
    const x = rect.left / window.innerWidth;
    const y = rect.top / window.innerHeight;

    fetch(`https://${GetParentResourceName()}/saveSettings`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            autoShow,
            position: { x, y },
            scale: 1.0
        })
    });

    settingsPanel.style.display = "none";
});

// === MOVE MODE ===
const moveBtn = document.getElementById("moveModeToggle");
if (moveBtn) {
    moveBtn.addEventListener("change", function () {
        isMoving = this.checked;
        container.style.cursor = isMoving ? "move" : "default";
    });
}

container.addEventListener("mousedown", function (e) {
    if (!isMoving) return;

    e.preventDefault();
    offsetX = e.clientX - container.offsetLeft;
    offsetY = e.clientY - container.offsetTop;

    document.addEventListener("mousemove", drag);
    document.addEventListener("mouseup", stopDrag);
});

function drag(e) {
    if (!isMoving) return;

    let x = e.clientX - offsetX;
    let y = e.clientY - offsetY;

    container.style.left = `${x}px`;
    container.style.top = `${y}px`;
    container.style.transform = "translate(0, 0)";
}

function stopDrag() {
    document.removeEventListener("mousemove", drag);
    document.removeEventListener("mouseup", stopDrag);
}
