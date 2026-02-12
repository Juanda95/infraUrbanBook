# UrbanBook Infrastructure - Docker Compose

Este directorio contiene la configuración de Docker Compose para ejecutar la aplicación UrbanBook con PostgreSQL.

## Requisitos previos

- Docker (versión 20.10 o superior)
- Docker Compose (versión 2.0 o superior)
- Git

## Estructura

```
InfraUrbanBook/
├── docker-compose.yml      # Configuración principal de Docker Compose
├── init-db.sql             # Script de inicialización de PostgreSQL
└── README.md               # Este archivo
```

## Servicios incluidos

### PostgreSQL (postgres)
- **Imagen**: postgres:16-alpine
- **Puerto**: 5432
- **Usuario**: postgres
- **Contraseña**: postgres_password_123
- **Base de datos**: UrbanBook
- **Volumen**: postgres_data (persistencia de datos)

### UrbanBook API (urbanbook-api)
- **Puert**: 5232 (interno, expuesto a través de Nginx)
- **Ambiente**: Production
- **Conexión BD**: Host=postgres (conecta con el servicio PostgreSQL)

### Nginx Reverse Proxy (UrbanBook-nginx)
- **Imagen**: nginx:alpine
- **Puerto**: 80 (HTTP)
- **Puerto**: 443 (HTTPS - configuración disponible)
- **Funcionalidades**:
  - Reverse proxy para la API
  - Rate limiting (20 req/s para API, 30 req/s general)
  - Health check endpoint en /health
  - Soporte para WebSocket
  - Headers de seguridad (X-Real-IP, X-Forwarded-For, etc.)

## Cómo usar

### 1. Iniciar los servicios

```bash
docker compose up -d
```

Esto levantará:
- PostgreSQL en background
- La API de UrbanBook en background

### 2. Ver los logs

```bash
# Ver logs de todos los servicios
docker compose logs -f

# Ver logs de un servicio específico
docker compose logs -f urbanbook-api
docker compose logs -f postgres
docker compose logs -f urbanbook-nginx
```

### 3. Acceder a la API

A través de **Nginx** (Reverse Proxy - Recomendado):
- **API Base**: http://localhost/api
- **Swagger UI**: http://localhost/swagger
- **Health Check**: http://localhost/health

O directamente (sin Nginx):
- **API Base**: http://localhost:5232
- **Swagger UI**: http://localhost:5232/swagger

### 4. Acceder a PostgreSQL

```bash
# Conectar con psql (si tienes PostgreSQL cliente instalado)
psql -h localhost -p 5432 -U postgres -d UrbanBook

# O usando Docker
docker compose exec postgres psql -U postgres -d UrbanBook
```

### 5. Detener los servicios

```bash
# Detener sin eliminar datos
docker compose stop

# Detener y eliminar contenedores
docker compose down

# Detener, eliminar contenedores Y eliminar datos
docker compose down -v
```

## Variables de entorno

Las credenciales por defecto son:
- **DB Usuario**: postgres
- **DB Contraseña**: postgres_password_123
- **DB Nombre**: UrbanBook

Para cambiarlas, edita el archivo `docker-compose.yml` en la sección `postgres` > `environment`.

## Health Checks

Ambos servicios incluyen health checks:
- **PostgreSQL**: Verifica que la BD esté lista cada 10 segundos
- **API**: Verifica que el endpoint /swagger sea accesible cada 30 segundos

Puedes ver el estado con:
```bash
docker compose ps
```

## Solución de problemas

### El API no conecta con la BD
1. Verifica que PostgreSQL esté saludable: `docker compose ps`
2. Verifica los logs: `docker compose logs postgres`
3. Asegúrate de que la cadena de conexión en el API sea correcta

### Puerto 80 ya está en uso (Nginx)
Cambia el mapeo de puertos en `docker-compose.yml`:
```yaml
ports:
  - "8080:80"  # Usa 8080 en lugar de 80
```
Luego accede a: http://localhost:8080

### Puerto 5432 ya está en uso
Cambia el mapeo de puertos en `docker-compose.yml`:
```yaml
ports:
  - "5433:5432"  # Usa 5433 en lugar de 5432
```

### Nginx no conecta con la API
1. Verifica que la API esté corriendo: `docker compose ps`
2. Revisa logs de Nginx: `docker compose logs urbanbook-nginx`
3. Asegúrate de que `nginx.conf` está en el directorio correcto
4. Reinicia Nginx: `docker compose restart urbanbook-nginx`

### Los datos de PostgreSQL persisten pero queremos limpiar
```bash
docker compose down -v  # Elimina los volúmenes
```

## Desarrollo vs Producción

La configuración actual es adecuada para **desarrollo local**.

Para producción, considera:
- Cambiar contraseñas por valores más seguros
- Usar un archivo `.env` para variables sensibles
- Añadir certificados SSL
- Configurar backups automáticos
- Usar health checks más robustos
- Aumentar límites de recursos

## Recursos de red

- **Red**: urbanbook-network (bridge)
- Permite comunicación interna entre servicios
- El API accede a PostgreSQL como `postgres:5432`

## Notas importantes

- Los datos de PostgreSQL se persisten en el volumen `postgres_data`
- El Dockerfile del API usa build de 3 etapas (build, publish, runtime) para optimizar el tamaño
- La aplicación se publica en modo Release para mejor rendimiento
