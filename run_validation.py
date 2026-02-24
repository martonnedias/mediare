import asyncio
import time
import httpx
import subprocess
import os
from playwright.async_api import async_playwright

async def wait_for_server(url, timeout=300):
    start = time.time()
    while time.time() - start < timeout:
        try:
            async with httpx.AsyncClient() as client:
                res = await client.get(url)
                if res.status_code == 200:
                    return True
        except Exception:
            pass
        await asyncio.sleep(2)
    return False

async def main():
    print("Iniciando Flutter Web Server...")
    flutter_env = os.environ.copy()
    flutter_process = subprocess.Popen(
        "flutter run -d web-server --web-port 3000 --web-hostname localhost",
        cwd=r"c:\Users\tonne\SITES\mediare_mgcf\frontend",
        stderr=subprocess.STDOUT,
        stdout=subprocess.PIPE,
        text=True,
        shell=True
    )
    
    print("Aguardando subida na porta 3000...")
    is_up = await wait_for_server("http://localhost:3000")
    if not is_up:
        print("Falha ao subir flutter.")
        flutter_process.kill()
        return

    print("Flutter OK! Capturando telas via Playwright...")
    try:
        async with async_playwright() as p:
            browser = await p.chromium.launch()
            context = await browser.new_context(viewport={'width': 1280, 'height': 800})
            page = await context.new_page()
            
            await page.goto("http://localhost:3000", wait_until='networkidle')
            await asyncio.sleep(10) # render
            
            out_dir = r"C:\Users\tonne\.gemini\antigravity\brain\a29f0fac-4f15-4834-b697-99fe0447293a"
            print("Capturando Login...")
            await page.screenshot(path=os.path.join(out_dir, "app_login_soft.png"))
            
            print("Capturando Dashboard...")
            await page.fill('input[type="email"]', "teste@gmail.com")
            await page.fill('input[type="password"]', "senha123")
            await page.get_by_text("ACESSAR PLATAFORMA").click()
            await asyncio.sleep(6)
            await page.screenshot(path=os.path.join(out_dir, "app_dashboard_soft.png"))
            
            await browser.close()
    except Exception as e:
        print("Erro no Playwright:", e)
        
    flutter_process.kill()
    print("Gerado.")

if __name__ == "__main__":
    asyncio.run(main())
