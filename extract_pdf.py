import sys
import subprocess

try:
    import fitz
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "PyMuPDF"])
    import fitz

files_to_read = [
    r'C:/Users/tonne/SITES/mediare_mgcf/Projeto Mediare Doc/Projeto Mediare v1.pdf',
    r'C:/Users/tonne/SITES/mediare_mgcf/Projeto Mediare Doc/Projeto Mediare v2.pdf'
]

with open("docs_pdfs_fixed.txt", "w", encoding="utf-8") as f_out:
    for f in files_to_read:
        f_out.write(f"\n\n--- {f} ---\n\n")
        try:
            doc = fitz.open(f)
            for page in doc:
                f_out.write(page.get_text())
        except Exception as e:
            f_out.write(f"Error reading PDF: {e}")

print("DONE_READING")
