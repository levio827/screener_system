# Kanban Board

This directory contains work tickets for the Stock Screening Platform project, organized in a Kanban-style workflow.

## Directory Structure

```
docs/kanban/
├── backlog/       # Future work, not yet prioritized
├── todo/          # Ready to start, prioritized
├── in_progress/   # Currently being worked on
├── review/        # Completed, awaiting review
├── done/          # Completed and reviewed
└── README.md      # This file
```

## Ticket Categories

Tickets are prefixed by category:

- **DB-XXX**: Database setup and migrations
- **BE-XXX**: Backend API development
- **FE-XXX**: Frontend development
- **DP-XXX**: Data Pipeline (Airflow)
- **INFRA-XXX**: Infrastructure and DevOps
- **TEST-XXX**: Testing (future tickets)

## Ticket Format

Each ticket follows this structure:

### Metadata
- Status: TODO | IN_PROGRESS | REVIEW | DONE
- Priority: Critical | High | Medium | Low
- Assignee: Team member or TBD
- Estimated Time: Hours or days
- Sprint: Sprint number (1-3 for MVP)
- Tags: Categorization tags

### Content
- **Description**: What needs to be done
- **Subtasks**: Checklist of specific tasks
- **Acceptance Criteria**: How to verify completion
- **Dependencies**: What this ticket depends on / blocks
- **References**: Related documentation
- **Progress**: Percentage complete
- **Notes**: Additional context

## Current Ticket Distribution

### Todo (Sprint 1 - Weeks 1-2) - Foundation
**14 tickets ready to start:**

**Database (4):**
- DB-001: PostgreSQL + TimescaleDB Environment Setup (Critical)
- DB-002: Database Schema Migration Implementation (Critical)
- DB-003: Indexes and Materialized Views Creation (High)
- DB-004: Database Functions and Triggers Implementation (Medium)

**Backend (4):**
- BE-001: FastAPI Project Initial Setup (Critical)
- BE-002: User Authentication API Implementation (Critical)
- BE-003: Stock Data API Implementation (Critical)
- BE-004: Stock Screening API Implementation (Critical)

**Frontend (3):**
- FE-001: React + Vite Project Setup (Critical)
- FE-002: User Authentication UI Implementation (Critical)
- FE-003: Stock Screener Page Implementation (Critical)

**Data Pipeline (2):**
- DP-001: Apache Airflow Environment Setup (High)
- DP-002: Daily Price Ingestion DAG Implementation (Critical)

**Infrastructure (1):**
- INFRA-001: Docker Compose Multi-Container Setup (High)

**Goal**: Development environment ready, authentication working, basic screening operational

### Backlog (Sprint 2+ - Weeks 3+) - Advanced Features
**9 tickets for future sprints:**

**Backend (2):**
- BE-005: API Rate Limiting and Throttling (Sprint 2, High)
- BE-006: WebSocket Real-time Price Streaming (Sprint 2-3, High)

**Database (1):**
- DB-005: Order Book Schema and Storage (Sprint 2, Medium)

**Data Pipeline (2):**
- DP-003: Indicator Calculation DAG Implementation (Sprint 2, Critical)
- DP-004: KIS API Integration (Sprint 2, Critical)

**Frontend (2):**
- FE-004: Stock Detail Page Implementation (Sprint 2, High)
- FE-005: Order Book Visualization Component (Sprint 2-3, Medium)

**Infrastructure (2):**
- INFRA-002: CI/CD Pipeline with GitHub Actions (Sprint 2, High)
- INFRA-003: Production Monitoring and Logging Setup (Sprint 2-3, Medium)

**Goal**: Real-time features, advanced visualization, production readiness

## Workflow

1. **Backlog**: Product backlog, not yet prioritized
2. **Todo**: Ready to start, prioritized by sprint
3. **In Progress**: Developer actively working (limit: 1-2 per person)
4. **Review**: Code review, testing, verification
5. **Done**: Merged to main, deployed to staging/production

## Moving Tickets

To move a ticket between stages:

```bash
# Move from todo to in_progress
mv docs/kanban/todo/BE-001.md docs/kanban/in_progress/

# Update status in file
# Change: **Status**: TODO
# To:     **Status**: IN_PROGRESS

# Update progress percentage as you work
```

## Ticket Dependencies

Always check dependencies before starting work:

```mermaid
graph LR
    DB-001 --> DB-002
    DB-002 --> DB-003
    DB-002 --> BE-001
    BE-001 --> BE-002
    BE-002 --> BE-003
    BE-003 --> BE-004
    DB-003 --> BE-004
```

## Team Guidelines

1. **Limit WIP**: Maximum 2 tickets in "In Progress" per person
2. **Update Progress**: Update progress percentage daily
3. **Blocked Tickets**: Add "BLOCKED" label and note blocker
4. **Review Time**: Aim for < 24 hour review turnaround
5. **Definition of Done**:
   - All subtasks completed ✓
   - All acceptance criteria met ✓
   - Tests passing ✓
   - Code reviewed ✓
   - Deployed to staging ✓

## Metrics

Track these metrics weekly:

- **Velocity**: Tickets completed per sprint
- **Cycle Time**: Average time from todo → done
- **Lead Time**: Average time from backlog → done
- **WIP**: Current work in progress count
- **Blocked**: Number of blocked tickets

## Sprint Planning

Before each sprint:

1. Review completed tickets
2. Calculate velocity
3. Prioritize backlog
4. Move tickets to todo (based on velocity)
5. Assign tickets to team members
6. Update sprint goals

## Daily Standup

Each team member answers:

1. What did I complete yesterday?
2. What am I working on today?
3. Am I blocked? (If yes, move ticket and add note)

## References

- **PRD**: Product requirements and features
- **SRS**: Detailed software requirements
- **SDS**: Technical design and architecture

---

Last Updated: 2025-11-09
