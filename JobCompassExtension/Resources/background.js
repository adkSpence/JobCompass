// Receives extracted job data from the popup, builds the deep link,
// then tells the content script to navigate — Safari only allows custom
// URL schemes to be triggered by the page itself, not the background script.

browser.runtime.onMessage.addListener((message, sender) => {
    if (message.action === "openInJobCompass") {
        const job = message.job;
        const params = new URLSearchParams();

        if (job.company)   params.set("company",   job.company);
        if (job.role)      params.set("role",       job.role);
        if (job.location)  params.set("location",   job.location);
        if (job.workType)  params.set("workType",   job.workType);
        if (job.salaryMin) params.set("salaryMin",  job.salaryMin);
        if (job.salaryMax) params.set("salaryMax",  job.salaryMax);
        if (job.url)       params.set("url",        job.url);

        const deepLink = `jobcompass://quickadd?${params.toString()}`;

        // Forward to content script in the active tab to do the navigation
        browser.tabs.query({ active: true, currentWindow: true }).then(([tab]) => {
            if (tab?.id) {
                browser.tabs.sendMessage(tab.id, { action: "navigate", url: deepLink });
            }
        });
    }
});
