# AI Subtitle Translator - Antigravity Configuration

## Project Overview
AI Subtitle Translator is an offline desktop CAT tool for professional subtitle translation powered by local LLMs (GGUF models via llama-cpp-python) and built with Python and PySide6 / Qt.

### Tech Stack
- **Language**: Python 3.11+
- **GUI Framework**: PySide6 (Qt Quick / QML & Widgets)
- **Inference Engine**: `llama-cpp-python` (Local LLM offline execution)
- **Testing Framework**: `pytest`, `pytest-qt`, `unittest.mock`
- **Virtual Environment**: `.venv` (`.\.venv\Scripts\python.exe`)
- **Key Modules**: `app/`, `models/`, `ui/`, `tests/`

---

## Test Automation Conventions

### Running Tests
Always run tests from the project root using the virtual environment:
```powershell
# Run a specific test file
.\.venv\Scripts\python.exe -m pytest tests/test_runtime_check.py -v

# Run all model/unit tests
.\.venv\Scripts\python.exe -m pytest tests/ -q

# Run with keyword filter
.\.venv\Scripts\python.exe -m pytest -k "translation"
```

### Test Standards
- **Mocking Local Models**: Do not invoke heavy GGUF inference in unit/regression tests. Mock `llama_cpp` bindings or inject lightweight fixture responses.
- **GUI Testing**: Use `pytest-qt` (`qtbot`) and `QTest` for QML/Widget interactions.
- **Explicit Waits**: Avoid raw `time.sleep()`. Rely on signals/slots and `qtbot.wait_until()`.

---

## QA Automation Skills & Agents

This project integrates [test-automation-skills-agents](https://github.com/fugazi/test-automation-skills-agents) for QA guidance.

### Assets Location
- **Agents**: `.agents/agents/`
- **Rules / Instructions**: `.agents/rules/`
- **Skills**: `.agents/skills/`

### Available Skills
| Skill | When to Use |
| --- | --- |
| `qa-manual-istqb` | Create test plans, test conditions, test cases, bug reports, and ISTQB QA artifacts for translation workflows |
| `qa-investigation` | Investigate flaky or failed tests, identify root causes, and propose deterministic fixes |
| `grill-me-qa` | Challenge test strategy, architectural edge cases, and translation validation logic |
| `api-testing` | API/service contract tests if local REST servers or cloud sync endpoints are added |
| `playwright-e2e-testing` | Browser-based E2E specs if web portal or companion web services exist |

### Available QA Agents (`.agents/agents/`)
| Agent | Invocation Example |
| --- | --- |
| **QA Orchestrator** | `"Read .agents/agents/qa-orchestrator.agent.md and design a test strategy for subtitle QA checks"` |
| **Test Refactor Specialist** | `"Read .agents/agents/test-refactor-specialist.agent.md and refactor tests/test_subtitle_model_qa.py for better maintainability"` |
| **Playwright Test Healer** / **QA Investigator** | `"Use qa-investigation to find why this test is failing intermittently: [error/code]"` |
| **Playwright Test Planner** | `"Read .agents/agents/playwright-test-planner.agent.md and build a test matrix for translation memory and glossary sync"` |
