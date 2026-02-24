import logging

# Configuração básica de logs estruturados
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
)

logger = logging.getLogger("mediare_mgcf")

# Exemplo de uso do logger
logger.info("Sistema iniciado com sucesso")