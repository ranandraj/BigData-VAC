# Session 4 - Apache NiFi

## Start
```powershell
.\scripts\session\03-START-NIFI.ps1
```

Open `https://localhost:8443/nifi`.

Credentials: `admin` / `BigDataLab123!`

## Build Flow 1
Create:

`GetFile -> ConvertRecord -> UpdateAttribute -> RouteOnAttribute -> PutFile`

Use the `data` directory as the source and separate CSV/JSON output into different folders.

## Build Flow 2
Create:

`ExecuteSQL -> ConvertRecord -> PutFile`

Use PostgreSQL as the source.

## Concepts to explain
FlowFile, Processor, Queue, attributes, routing, transformation, back pressure and processor status.
