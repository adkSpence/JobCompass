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

        try {
            await browser.scripting.executeScript({
                target: { tabId: tab.id },
                files: ["content.js"]
            });
        } catch (_) {}

        let job = null;
        try {
            job = await browser.tabs.sendMessage(tab.id, { action: "extractJob" });
        } catch (_) {}

        $("company").value  = job?.company  || "";
        $("role").value     = job?.role     || "";
        $("location").value = job?.location || "";

        const wt = $("workType");
        if (job?.workType) wt.value = job.workType;

        wt.dataset.salaryMin = job?.salaryMin || "";
        wt.dataset.salaryMax = job?.salaryMax || "";
        wt.dataset.url       = job?.url || tab.url;

        if (!job?.company && !job?.role) {
            document.getElementById("hint").classList.remove("hidden");
        }

        show("found");
    } catch (err) {
        $("workType").dataset.url = "";
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

    const params = new URLSearchParams();
    if (job.company)   params.set("company",   job.company);
    if (job.role)      params.set("role",       job.role);
    if (job.location)  params.set("location",   job.location);
    if (job.workType)  params.set("workType",   job.workType);
    if (job.salaryMin) params.set("salaryMin",  job.salaryMin);
    if (job.salaryMax) params.set("salaryMax",  job.salaryMax);
    if (job.url)       params.set("url",        job.url);

    const deepLink = `jobcompass://quickadd?${params.toString()}`;

    // Open from the popup page itself — extension pages have no CSP restrictions
    // so custom URL schemes work here, unlike content scripts on third-party pages.
    const a = document.createElement("a");
    a.href = deepLink;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);

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
