# VectorCraft Automation — Master Reference

## Project Purpose

Build a reliable automation environment that translates design
intent into structured document and vector-design operations.

The human defines intent and makes design decisions.
The automation layer validates inputs, executes commands,
measures outcomes, and reports results.

## Project Structure

- `Resume.ps1`
  Safe recovery entry point. Opens the workspace, starts or
  detects VectorCraft, and checks the existing connection.

- `Start.ps1`
  Existing document workflow entry point.
  CAUTION: this script may create a new document.
  Do not use it merely to resume a work session.

- `Launch.ps1`
  Starts VectorCraft in control mode or detects an available
  control port.

- `Core/Connection.ps1`
  TCP request/response functions and preset lookup.

- `Core/ConfigEngine.ps1`
  Loads JSON configuration and resolves document presets.

- `Core/DocumentEngine.ps1`
  Creates a document through the VectorCraft API.

- `Core/SaveEngine.ps1`
  Saves a document. Verify the actual API format and save
  response before treating every save as fully validated.

- `Modules/A4-Resume/config.json`
  Resume module configuration.

- `Output/`
  Intended destination for generated files.

- `Logs/`
  Recovery session logs.

- `PROJECT-STATE.json`
  Current project stage, confirmed capabilities, and next action.

## Safe Resume Procedure

1. Run `Resume.ps1` or use the Desktop recovery shortcut.
2. Confirm the VS Code workspace opens.
3. Confirm VectorCraft reports that its control port is ready.
4. Confirm the API returns Print preset data.
5. Continue from the next action in `PROJECT-STATE.json`.

## Safety Rules

- Never run document creation automatically during recovery.
- Never overwrite existing source files without an explicit decision.
- Treat API success responses and verified filesystem output
  as separate checks.
- Do not assume that a file extension proves the native format.
- Save important design documents independently of this project.
- Use version control or backups before major code changes.

## Current Known Stage

The connection, launch, configuration, document creation,
and save-engine files are present in the project.

The current task is to establish reliable session recovery.
The next engineering task is to validate save behavior and
then continue the design/layout automation pipeline.

This document is the project map, not a replacement for the
individual source files.
