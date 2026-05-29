let uiOpened = false
// lua vers nui
window.addEventListener('message', function(event) {

    if (event.data.action === "open") {
        uiOpened = true
        document.getElementById("container").style.display = "flex"
        document.getElementById("wordInput").value = ""
    }

    if (event.data.action === "closeUI") {
        uiOpened = false
        console.log("closeUI event received from client")
        document.getElementById("container").style.display = "none"
        document.getElementById("guessContainer").style.display = "none"
    }
    if (event.data.action === "closeGuessUI") {
        uiOpened = false
        console.log("closeGuessUI event received from client")
        document.getElementById("guessContainer").style.display = "none"
    }

    if (event.data.action === "updateQueue") {

        document.getElementById("queueCount").innerHTML =
        "👥 Joueurs dans la queue : " + event.data.count

    }

    if (event.data.action === "openGuessUI") {
        uiOpened = true
        document.getElementById("guessContainer").style.display = "flex"
        document.getElementById("guessInput").value = ""
    }

})

window.addEventListener('keydown', function(event) {

    if (event.key === "Escape" && uiOpened) {
        const guessContainer = document.getElementById("guessContainer")
        const container = document.getElementById("container")
        
        // Notifier Lua selon quel conteneur est ouvert
        if (guessContainer.style.display === "flex") {
            fetch(`https://${GetParentResourceName()}/closeGuessUI`, {
                method: 'POST'
            })
        } else if (container.style.display === "flex") {
            fetch(`https://${GetParentResourceName()}/closeUI`, {
                method: 'POST'
            })
        }
        
        container.style.display = "none"
        guessContainer.style.display = "none"
        uiOpened = false
    }
})


// nui vers lua
function submitWord() {

    const word = document.getElementById("wordInput").value

    fetch(`https://${GetParentResourceName()}/submitWord`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            word: word
        })
    })

    //document.getElementById("container").style.display = "none"
}

function submitGuess() {

    const guess = document.getElementById("guessInput").value

    fetch(`https://${GetParentResourceName()}/submitGuess`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            guess: guess
        })
    })

}

// nui vers lua
function closeUI() {

    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST'
    })

    document.getElementById("container").style.display = "none"
    document.getElementById("guessContainer").style.display = "none"
}

function closeGuessUI() {

    fetch(`https://${GetParentResourceName()}/closeGuessUI`, {
        method: 'POST'
    })

    document.getElementById("guessContainer").style.display = "none"
}

