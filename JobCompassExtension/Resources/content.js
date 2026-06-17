// Extracts job details from the current page and returns them to the popup.
// Strategy 1: JSON-LD (most reliable — used by LinkedIn, Greenhouse, Lever, etc.)
// Strategy 2: Site-specific DOM selectors as fallback

function extractJobDetails() {
    const result = {
        company: null,
        role: null,
        location: null,
        workType: null,
        salaryMin: null,
        salaryMax: null,
        url: window.location.href
    };

    // --- Strategy 1: JSON-LD structured data ---
    const scripts = document.querySelectorAll('script[type="application/ld+json"]');
    for (const script of scripts) {
        try {
            const data = JSON.parse(script.textContent);
            const job = findJobPosting(data);
            if (job) {
                applyJsonLd(job, result);
                break;
            }
        } catch (_) {}
    }

    // --- Strategy 2: DOM fallbacks per site ---
    const host = window.location.hostname;

    if (!result.role || !result.company) {
        if (host.includes("linkedin.com")) extractLinkedIn(result);
        else if (host.includes("indeed.com")) extractIndeed(result);
        else if (host.includes("glassdoor.com")) extractGlassdoor(result);
        else if (host.includes("greenhouse.io")) extractGreenhouse(result);
        else if (host.includes("lever.co")) extractLever(result);
        else if (host.includes("workday.com") || host.includes("myworkdayjobs.com")) extractWorkday(result);
    }

    // Normalise work type
    result.workType = normaliseWorkType(result.workType, result.location, document.body.innerText);

    return result;
}

// Recurse into @graph arrays to find a JobPosting node
function findJobPosting(data) {
    if (!data) return null;
    if (data["@type"] === "JobPosting") return data;
    if (Array.isArray(data)) {
        for (const item of data) {
            const found = findJobPosting(item);
            if (found) return found;
        }
    }
    if (data["@graph"]) return findJobPosting(data["@graph"]);
    return null;
}

function applyJsonLd(job, result) {
    result.role = result.role || job.title || job.name || null;
    result.company = result.company || job.hiringOrganization?.name || null;

    const loc = job.jobLocation;
    if (loc) {
        const place = Array.isArray(loc) ? loc[0] : loc;
        const addr = place?.address;
        if (typeof addr === "string") {
            result.location = result.location || addr;
        } else if (addr) {
            const city = addr.addressLocality || "";
            const country = addr.addressCountry || "";
            result.location = result.location || [city, country].filter(Boolean).join(", ");
        }
    }

    if (!result.workType) {
        result.workType = job.jobLocationType || job.workHours || null;
    }

    // Salary
    const salary = job.baseSalary || job.estimatedSalary;
    if (salary?.value) {
        const val = salary.value;
        result.salaryMin = val.minValue || val.value || null;
        result.salaryMax = val.maxValue || val.value || null;
    }
}

// --- Site-specific DOM extractors ---

function extractLinkedIn(r) {
    r.role = r.role || text(".job-details-jobs-unified-top-card__job-title h1")
                     || text(".topcard__title");
    r.company = r.company || text(".job-details-jobs-unified-top-card__company-name a")
                           || text(".topcard__org-name-link");
    r.location = r.location || text(".job-details-jobs-unified-top-card__primary-description-container .tvm__text")
                              || text(".topcard__flavor--bullet");
}

function extractIndeed(r) {
    r.role = r.role || text('[data-testid="jobsearch-JobInfoHeader-title"] span')
                     || text(".jobsearch-JobInfoHeader-title");
    r.company = r.company || text('[data-testid="inlineHeader-companyName"] a')
                           || text(".jobsearch-InlineCompanyRating-companyHeader");
    r.location = r.location || text('[data-testid="job-location"]');
}

function extractGlassdoor(r) {
    r.role = r.role || text('[data-test="job-title"]') || text(".job-title");
    r.company = r.company || text('[data-test="employer-name"]') || text(".employer-name");
    r.location = r.location || text('[data-test="location"]') || text(".location");
}

function extractGreenhouse(r) {
    r.role = r.role || text(".app-title") || text("h1.job-post-name");
    r.company = r.company || text(".company-name") || document.title.split(" at ").pop()?.trim();
    r.location = r.location || text(".location") || text(".job-post-location");
}

function extractLever(r) {
    r.role = r.role || text(".posting-headline h2");
    r.company = r.company || text(".main-header-logo img")?.alt
                           || document.title.split(" - ").pop()?.trim();
    r.location = r.location || text(".posting-categories .location");
    r.workType = r.workType || text(".posting-categories .workplaceTypes");
}

function extractWorkday(r) {
    r.role = r.role || text('[data-automation-id="jobPostingHeader"]')
                     || text("h2.css-1q2dra3");
    r.company = r.company || text('[data-automation-id="jobPostingCompanyName"]')
                           || document.querySelector("title")?.textContent?.split("|").pop()?.trim();
    r.location = r.location || text('[data-automation-id="locations"]');
}

// --- Helpers ---

function text(selector) {
    return document.querySelector(selector)?.textContent?.trim() || null;
}

function normaliseWorkType(rawType, location, bodyText) {
    const combined = [rawType, location, bodyText.slice(0, 2000)]
        .filter(Boolean).join(" ").toLowerCase();
    if (combined.includes("remote") || rawType === "TELECOMMUTE") return "Remote";
    if (combined.includes("hybrid")) return "Hybrid";
    if (combined.includes("on-site") || combined.includes("onsite") || combined.includes("in-office")) return "Onsite";
    return null;
}

// Listen for messages from the popup
browser.runtime.onMessage.addListener((message, _sender, sendResponse) => {
    if (message.action === "extractJob") {
        sendResponse(extractJobDetails());
    }
});
