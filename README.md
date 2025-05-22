# 🧹 ForceDelete-GUI.ps1

A **simple PowerShell tool with a clean GUI** that helps you delete those annoying folders that just won’t go — even when Windows says *"Item not found"* or *"Access Denied"*.

---

## ✅ What This Tool Does

- Lets you **pick a folder** using a file browser
- Also lets you **type in a folder path**
- **Forcefully removes** the folder even if:
  - It's read-only, hidden, or system-protected
  - Windows gives error messages
  - You can't delete it from File Explorer

---

## 🧑‍💻 Who’s It For?

- Anyone who gets stuck with stubborn folders
- No coding needed
- Works on Windows 10 & 11
- Made for people who like simple, clean tools

---

## 🚀 How to Use It

### 📌 Easiest Way (1-liner in PowerShell)

Just copy and paste this into PowerShell:

```powershell
irm https://raw.githubusercontent.com/yadavnikhil03/ForceDelete-GUI/main/ForceDelete.ps1 | iex
