# Integración Docker de UrbanBook

## Arquitectura

La aplicación UrbanBook ahora está completamente dockerizada con 4 servicios:

1. **PostgreSQL** - Base de datos
2. **UrbanBook API** - Backend .NET
3. **UrbanBook Frontend** - React/Vite
4. **Nginx** - Reverse proxy

## Estructura de URLs

- `http://localhost/` → Frontend React
- `http://localhost/api/*` → Backend API
- `http://localhost/swagger` → Documentación Swagger

## Configuración del Frontend

### Variables de Entorno

Crea un archivo `.env` en `UrbanBookFrontJsx/` basado en `.env.example`:

```bash
VITE_API_URL=http://localhost/api
```

### Actualizar Axios en el Frontend

Asegúrate de que las llamadas API en tu frontend usen la variable de entorno:

```javascript
// En tu configuración de axios
const API_URL = import.meta.env.VITE_API_URL || 'http://localhost/api';
```

## Instrucciones de Uso

### 1. Levantar todos los servicios

```bash
cd InfraUrbanBook
docker-compose up -d
```

### 2. Ver logs

```bash
# Todos los servicios
docker-compose logs -f

# Un servicio específico
docker-compose logs -f urbanbook-frontend
docker-compose logs -f urbanbook-api
```

### 3. Verificar estado

```bash
docker-compose ps
```

### 4. Reconstruir después de cambios

```bash
# Reconstruir frontend
docker-compose up -d --build urbanbook-frontend

# Reconstruir backend
docker-compose up -d --build urbanbook-api

# Reconstruir todo
docker-compose up -d --build
```

### 5. Detener servicios

```bash
docker-compose down

# Con eliminación de volúmenes
docker-compose down -v
```

## Healthchecks

Todos los servicios tienen healthchecks configurados:
- PostgreSQL: Verifica conexión a la base de datos
- API: `/health` endpoint
- Frontend: Verifica que nginx esté sirviendo
- Nginx: `/health` endpoint

## Desarrollo Local

### Opción 1: Todo en Docker
Usa `docker-compose up -d` para levantar todo.

### Opción 2: Desarrollo Híbrido

Si quieres desarrollar el frontend localmente con hot reload:

1. Levanta solo backend y base de datos:
```bash
docker-compose up -d postgres urbanbook-api nginx
```

2. Ejecuta el frontend localmente:
```bash
cd UrbanBookFrontJsx
npm install
npm run dev
```

3. Actualiza `.env` para desarrollo local:
```bash
VITE_API_URL=http://localhost/api
```

## Solución de Problemas

### El frontend no carga
```bash
docker-compose logs urbanbook-frontend
docker-compose restart urbanbook-frontend
```

### Error de conexión API
- Verifica que el backend esté corriendo: `docker-compose ps`
- Verifica los logs: `docker-compose logs urbanbook-api`
- Verifica la configuración de nginx: `docker-compose logs nginx`

### Reconstruir desde cero
```bash
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
```

## Configuración de Producción

Para producción, considera:

1. **Variables de entorno**: Usa archivos `.env` separados
2. **SSL/HTTPS**: Configura certificados en nginx
3. **Dominios**: Actualiza `server_name` en nginx.conf
4. **Seguridad**: Cambia las contraseñas de la base de datos
5. **Recursos**: Ajusta límites de memoria y CPU en docker-compose

## Puertos Expuestos

- **80**: Nginx (HTTP) - Punto de entrada principal
- **443**: Nginx (HTTPS) - Para configurar SSL
- **5432**: PostgreSQL - Acceso directo a la BD (para desarrollo)

Los servicios internos (API:5232, Frontend:80) no están expuestos directamente, solo accesibles a través de Nginx.
