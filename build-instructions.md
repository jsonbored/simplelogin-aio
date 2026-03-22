# SimpleLogin Build Pipeline Instructions

Read `/home/node/clawd/simplelogin/build-status.md` to find the current step. Execute exactly one step from the list below, save the output file, update `build-status.md` to mark that step complete, then stop. If all steps are complete, disable the cron job and notify the user in chat.

**Rules for every step:** 
- Never generate from memory. 
- Always read from files already saved in `/home/node/clawd/simplelogin/`. 
- Each file must be complete and production quality. 
- If a step produces output shorter than 100 lines, that is a failure — redo it.

**The steps in order:**
Step 1: cat `/home/node/clawd/simplelogin/example.env.raw` and save full contents to `research-v3.md` with every variable documented — name, purpose, required/optional, default, sensitive yes/no, display always/advanced
Step 2: Write `architecture.md` documenting the 3-process s6-overlay architecture, startup sequence, and init script logic based on `research-v3.md`
Step 3: Write `Dockerfile`
Step 4: Write `rootfs/etc/cont-init.d/01-validate-env.sh`
Step 5: Write `rootfs/etc/cont-init.d/02-dkim-setup.sh`
Step 6: Write `rootfs/etc/cont-init.d/03-write-env.sh` — must translate every SL_ variable from `research-v3.md` into the exact format SimpleLogin expects in `/code/.env*`
Step 7: Write `rootfs/etc/cont-init.d/04-db-migrate.sh`
Step 8: Write `rootfs/etc/services.d/simplelogin-web/run`
Step 9: Write `rootfs/etc/services.d/simplelogin-email/run`
Step 10: Write `rootfs/etc/services.d/simplelogin-job/run`
Step 11: Write `.github/workflows/build.yml`
Step 12: Write `SimpleLogin-AIO.xml` — must include every variable from `research-v3.md` with full descriptions
Step 13: Write `SimpleLogin-Postfix.xml` — must include relay mode dropdown with direct/protonmail/brevo/gmail/mailgun/custom options and all associated credential variables
Step 14: Write `docs/simplelogin-setup.md`
Step 15: Write `blog-post-draft.md`
Step 16: Write `reddit-angles.md`
Step 17: Write `youtube-outline.md`