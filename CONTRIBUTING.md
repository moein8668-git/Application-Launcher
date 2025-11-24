# Contributing to Application Launcher

Thank you for your interest in contributing to the **Application Launcher** project! We welcome all contributions, from bug fixes and code improvements to documentation updates and new features.

Please take a moment to review this document to ensure a smooth and effective contribution process.

---

## 🐞 Reporting Bugs

If you find a bug in the application or configuration, please help us by submitting an issue on the GitHub Issues page.

**Before submitting a bug report:**

1.  **Check Existing Issues:** Search the existing issues to see if the bug has already been reported.
2.  **Verify Latest Version:** Ensure you are testing against the latest code from the `main` branch.

**When submitting a bug report, please include:**

* **A clear and descriptive title.**
* **Steps to reproduce:** Detail the exact actions that lead to the bug.
* **Expected behavior:** What you expected the application to do.
* **Actual behavior:** What the application actually did.
* **Environment:**
    * Windows Version (e.g., Windows 10, Windows 11)
    * PowerShell Version (Run `$PSVersionTable.PSVersion`)
    * Any specific `config.json` entry that triggers the bug.

---

## ✨ Suggesting Enhancements

If you have an idea for a new feature, a UI improvement, or a better way to structure the code, please submit a feature request on the GitHub Issues page.

**When suggesting an enhancement:**

* **Explain the use case:** Describe the problem you are trying to solve and why this enhancement is valuable.
* **Provide a mock-up (optional):** A simple sketch or description of how the new feature would look in the GUI is helpful.
* **Keep it focused:** Suggest one new feature or improvement per issue.

---

## 💻 Making a Pull Request (PR)

Pull Requests are the best way to get your code changes into the project.

### General Guidelines

1.  **Fork the repository** and clone it locally.
2.  **Create a new branch** for your feature or fix (e.g., `feat/add-new-type` or `fix/gui-alignment`).
3.  **Ensure you are running the script as Administrator** during testing to catch any privilege-related errors.
4.  **Use PowerShell Standards:** Follow standard PowerShell naming conventions (e.g., `Verb-Noun` for functions).
5.  **Use Tabs/Spaces Consistently:** Maintain the existing indentation style of the project.
6.  **Update Documentation:** If you add a new configuration option or change existing behavior, update the `README.md` accordingly.

### Submission Checklist

Before submitting your Pull Request, please ensure the following:

* [ ] Your branch is up-to-date with the `main` branch.
* [ ] Your code is properly tested and does not introduce new bugs.
* [ ] Your changes address only the bug or feature described in the PR title.
* [ ] The PR title is descriptive (e.g., `FIX: Corrected parallel task status updates`).
* [ ] You have described the changes made and the reason for the change in the PR body.

Thank you for helping to improve the Application Launcher!
