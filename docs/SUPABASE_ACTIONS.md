# Supabase desde GitHub Actions

El flujo `Grupli Supabase` prueba los parches en PostgreSQL temporal. Un push
ejecuta pruebas y comprueba la conexión real sin cambiar el esquema ni los datos.
No ejecuta SQL arbitrario y no usa un
token personal de Supabase con acceso a otros proyectos.

## Configuración inicial por el propietario

En Supabase, abrir **Grupli → Connect → Session pooler**, puerto **5432**.
Copiar la URI PostgreSQL y sustituir `[YOUR-PASSWORD]` por la contraseña de la
base de datos (no es la contraseña del inicio de sesión). Codificar caracteres
reservados de la contraseña según la documentación oficial. No enviar la URI
por chat ni guardarla como archivo del repositorio. Si no se conoce la
contraseña, detenerse antes de restablecerla: otros servicios podrían usarla.

En **GitHub → grupli → Settings → Secrets and variables → Actions → New
repository secret**, guardar:

- `GRUPLI_DATABASE_URL`: la URI completa de Session pooler de Grupli.
- `GRUPLI_DATABASE_CA_CERT`: el contenido PEM del certificado CA público que
  se descarga en Supabase, configuración de la base de datos, SSL. No una clave
  privada. La comprobación TLS exige certificado válido y nombre de servidor.

La URI da acceso privilegiado a esta base de datos: cualquier persona con
permiso para modificar workflows podría usar ese secreto. Conservar el
repositorio privado y restringir sus colaboradores. Nunca usar `service_role`,
anon ni publishable como contraseña de PostgreSQL.

## Ejecución

**Actions → Grupli Supabase → Run workflow → main**. Dejar `apply` desmarcado
para probar exclusivamente conexión y prerrequisito financiero. Cuando pase,
repetir con `apply` marcado para instalar únicamente la transferencia segura
de grupos ya probada. El script comprueba el proyecto, usa TLS `verify-full`,
no imprime credenciales y valida función, trigger y permisos antes del commit.
Un error SQL revierte la transacción; un corte de red puede dejar resultado
desconocido, por lo que debe consultarse el estado antes de reintentar.

No se ejecutan bootstrap, all_in_one ni fixtures contra producción. No aplica
automáticamente futuras migraciones ni publica la app. No resuelve por sí solo
los cambios de frontend pendientes. Los minutos de Actions consumen la cuota
del plan: mantener gasto adicional bloqueado en la facturación de GitHub; no
contratar runners ni planes. No añadir tareas programadas.

Documentación: https://supabase.com/docs/guides/database/connecting-to-postgres
y https://supabase.com/docs/guides/database/psql.
