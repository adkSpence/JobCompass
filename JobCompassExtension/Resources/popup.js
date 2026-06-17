const $ = id => document.getElementById(id);

function show(id) {
    ["loading", "found"].forEach(s =>
        $(s).classList.toggle("hidden", s !== id)
    );
}

async function init() {
    show("loading");
    try {
        const [tab] = await browser.tabs.query({ active: true, currentWindow: true });

        // Try injecting content script on demand (covers pages not in manifest matches)
        try {
            await browser.scripting.executeScript({
                target: { tabId: tab.id },
                files: ["content.js"]
            });
        } catch (_) {}

        // Ask content script for extracted data
        let job = null;
        try {
            job = await browser.tabs.sendMessage(tab.id, { action: "extractJob" });
        } catch (_) {}

        // Always show the form — pre-fill whatever we found, leave the rest blank
        $("company").value  = job?.company  || "";
        $("role").value     = job?.role     || "";
        $("location").value = job?.location || "";

        const wt = $("workType");
        if (job?.workType) wt.value = job.workType;

        wt.dataset.salaryMin = job?.salaryMin || "";
        wt.dataset.salaryMax = job?.salaryMax || "";
        wt.dataset.url       = job?.url || tab.url;

        // Show a subtle hint if nothing was auto-detected
        if (!job?.company && !job?.role) {
            const hint = document.getElementById("hint");
            if (hint) hint.classList.remove("hidden");
        }

        show("found");
    } catch (err) {
        // Even on error, show the blank form so the user can type manually
        const wt = $("workType");
        wt.dataset.url = "";
        show("found");
        console.error("JobCompass popup error:", err);
    }
}

$("addBtn").addEventListener("click", () => {
    const job = {
        company:   $("company").value.trim(),
        role:      $("role").value.trim(),
        location:  $("location").value.trim(),
        workType:  $("workType").value,
        salaryMin: $("workType").dataset.salaryMin,
        salaryMax: $("workType").dataset.salaryMax,
        url:       $("workType").dataset.url
    };

    if (!job.company || !job.role) {
        showNotice("Company and role are required.", true);
        return;
    }

    browser.runtime.sendMessage({ action: "openInJobCompass", job });
    showNotice("Opening JobCompass…");
    $("addBtn").disabled = true;
    setTimeout(() => window.close(), 1200);
});

function showNotice(msg, isError = false) {
    const el = $("notice");
    el.textContent = msg;
    el.className = "notice" + (isError ? " error" : "");
    el.classList.remove("hidden");
}

init();
