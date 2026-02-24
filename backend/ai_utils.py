import os
import json
from google import genai
from google.genai import types

# Configuração do Gemini via google-genai SDK
class GeminiClient:
    def __init__(self, model_lite: str = "gemini-2.5-flash"):
        self.use_vertex = False
        api_key = os.environ.get("GOOGLE_API_KEY")
        
        # Tenta usar Vertex AI se houver arquivo de credenciais
        json_path = os.path.join(os.path.dirname(__file__), "mediare-486816-9b6669540750.json")
        
        if os.path.exists(json_path):
            try:
                os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = json_path
                self.client = genai.Client(
                    vertexai=True,
                    project="mediare-486816",
                    location="us-central1"
                )
                self.use_vertex = True
                self.model_id = model_lite
                print(f"GeminiClient: Conectado ao Vertex AI via google-genai. Modelo: {model_lite}")
            except Exception as e:
                print(f"GeminiClient: Erro ao inicializar Vertex AI: {e}. Tentando fallback para SDK direto.")
        
        if not self.use_vertex:
            if not api_key:
                print("GeminiClient AVISO: Nenhuma GOOGLE_API_KEY encontrada.")
            self.client = genai.Client(api_key=api_key)
            # Usando modelo da lista disponível: gemini-2.5-flash
            self.model_id = "gemini-2.5-flash"
            print("GeminiClient: Conectado ao Google AI Studio (API Key).")

    def generate_content(self, prompt: str):
        """Gera conteúdo textual simples."""
        try:
            response = self.client.models.generate_content(
                model=self.model_id,
                contents=prompt
            )
            return response.text
        except Exception as e:
            print(f"GeminiClient Erro (generate_content): {e}")
            return None

    def analyze_json(self, prompt: str):
        """
        Envia um prompt esperando uma resposta JSON.
        Trata a limpeza de markdown se a IA retornar blocos ```json ... ```.
        """
        try:
            response = self.client.models.generate_content(
                model=self.model_id,
                contents=prompt
            )
            text = response.text.strip()
            
            # Limpeza de blocos de código Markdown
            if text.startswith("```json"):
                text = text[7:]
            elif text.startswith("```"):
                text = text[3:]
                
            if text.endswith("```"):
                text = text[:-3]
            
            return json.loads(text.strip())
        except Exception as e:
            print(f"GeminiClient Erro (analyze_json): {e}")
            return None

    def analyze_image(self, prompt: str, image_bytes: bytes, mime_type: str = "image/jpeg"):
        """
        Analisa uma imagem combinada com um prompt.
        """
        try:
            response = self.client.models.generate_content(
                model=self.model_id,
                contents=[
                    prompt,
                    types.Part.from_bytes(data=image_bytes, mime_type=mime_type)
                ]
            )
            text = response.text.strip()
            
            # Limpeza JSON básica
            if "```json" in text:
                text = text.split("```json")[1].split("```")[0]
            elif "```" in text:
                text = text.split("```")[1].split("```")[0]
            
            try:
                return json.loads(text.strip())
            except:
                return {"text": text}
        except Exception as e:
            print(f"GeminiClient Erro (analyze_image): {e}")
            return None

    def analyze_audio(self, prompt: str, audio_bytes: bytes, mime_type: str = "audio/mpeg"):
        """
        Analisa um áudio combinado com um prompt.
        """
        try:
            response = self.client.models.generate_content(
                model=self.model_id,
                contents=[
                    prompt,
                    types.Part.from_bytes(data=audio_bytes, mime_type=mime_type)
                ]
            )
            text = response.text.strip()
            
            if "```json" in text:
                text = text.split("```json")[1].split("```")[0]
            
            try:
                return json.loads(text.strip())
            except:
                return {"text": text}
        except Exception as e:
            print(f"GeminiClient Erro (analyze_audio): {e}")
            return None

# Instância singleton
gemini_client = GeminiClient()
