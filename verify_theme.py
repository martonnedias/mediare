import asyncio
import time
import httpx
from playwright.async_api import async_playwright
import os

async def wait_for_server(url, timeout=300):
    start = time.time()
    while time.time() - start < timeout:
        try:
            async with httpx.AsyncClient() as client:
                res = await client.get(url)
                if res.status_color == 200 or res.status_code == 200:
                    return True
        except Exception:
            pass
        await asyncio.sleep(2)
    return False

async def main():
    print("Aguardando servidor Flutter iniciar...")
    is_up = await wait_for_server("http://localhost:3000")
    if not is_up:
        print("Servidor nao subiu a tempo.")
        return

    print("Servidor no ar. Iniciando Playwright...")
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        # Desktop context
        context = await browser.new_context(viewport={'width': 1280, 'height': 800})
        page = await context.new_page()
        
        await page.goto("http://localhost:3000", wait_until='networkidle')
        await asyncio.sleep(5)
        
        artifact_path = r"C:\Users\tonne\.gemini\antigravity\brain\a29f0fac-4f15-4834-b697-99fe0447293a"
        
        try:
            # Captura Login
            print("Capturando Tela de Login...")
            await page.screenshot(path=os.path.join(artifact_path, "verify_login.png"))
            
            # Navegar para Signup
            await page.get_by_text("Ainda não tem conta? Criar Conta").click()
            await asyncio.sleep(2)
            print("Capturando Tela de Cadastro (Soft Theme)...")
            await page.screenshot(path=os.path.join(artifact_path, "verify_signup.png"))
            
            # Voltar
            await page.get_by_role("button").first.click() # Button back
            await asyncio.sleep(1)
            
            # Login manual
            await page.fill('input[type="email"]', 'teste123@gmail.com')
            await page.fill('input[type="password"]', 'senha123')
            await page.get_by_text("ACESSAR PLATAFORMA").click()
            await asyncio.sleep(6) # Esperar home carregar
            
            # Capturar Home
            print("Capturando Dashboard...")
            await page.screenshot(path=os.path.join(artifact_path, "verify_home.png"))
            
            # Clicar menu e capturar algumas outras
            await page.get_by_role("button", name="Open navigation menu").click()
            await asyncio.sleep(1)
            # Ir pro Calendario
            await page.get_by_text("Calendário e Convivência").first.click()
            await asyncio.sleep(2)
            print("Capturando Calendário...")
            await page.screenshot(path=os.path.join(artifact_path, "verify_calendar.png"))
            
        except Exception as e:
            print("Erro durante navegacao:", e)
        
        await browser.close()
        print("Finalizado!")

if __name__ == "__main__":
    asyncio.run(main())
