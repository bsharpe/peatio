## Introduction

  This is a clone of scatterp/peatio that I wanted to mess around with and practice my refactoring skills.
  In the process, I wanted to learn a little more about how these exchanges work, and possibly see how Rails & Ruby can build a scalable system.

  I have worked on some projects that had to scale handling thousands of transactions a month to millions a day, so I feel confident I can finish this project.

  If you'd like to help, submit a PR and we'll chat.

### Can I use this in Production?

# NO.

### Recently done / News

### Master Branch

  - upgraded all gems (staying with Rails 4.2)
  - got tests to pass
  - got website to render in dev mode

### Rails 5 Branch

  - upgrading to Rails 5.x
  - switching to PostgreSQL from MySQL
    - I'm personally more familiar with the scaling options of Postgres
    - Better features (JSONB, integrated search, etc.)
  - Turning models into CRUD objects only
  - Creating Service objects (using the awesome Interactor gem) for all business logic
  - remove vestigal dependencies on old gems
  - upgrade to Bootstrap 4 (or something else)

## TODO

 - separate frontend from backend
 - re-evaluate use of AMQP
 - evaluate performance under load
 - simplify logic


