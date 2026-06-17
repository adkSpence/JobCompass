// Receives extracted job data from popup and fires the URL scheme
// to hand off to the native JobCompass app.

browser.runtime.onMessage.addListener((message, _sender) => {
    if (message.action === "openInJobCompass") {
        const job = message.job;
        const params = new URLSearchParams();

        if (job.company)   params.set("company",  job.company);
        if (job.role)      params.set("role",      job.role);
        if (job.location)  params.set("location",  job.location);
        if (job.workType)  params.set("workType",  job.workType);
        if (job.salaryMin) params.set("salaryMin", job.salaryMin);
        if (job.salaryMax) params.set("salaryMax", job.salaryMax);
        if (job.url)       params.set("url",       job.url);

        const deepLink = `jobcompass://quickadd?${params.toString()}`;
        browser.tabs.update({ url: deepLink });
    }
});
