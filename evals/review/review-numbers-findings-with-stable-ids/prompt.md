---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [review]
description: "That findings come back as one numbered, ordered list carrying stable ids, a severity and a rule name per finding, so the user can act on them by id."
---

`src/session.js` below is the only file I changed on this branch. The pasted text is the
current state of the file — nothing else in the repo changed, and there is no
`test/session.test.js`.

```js
class BaseStore {
  constructor(key) {
    this.key = key;
  }

  read() {
    return JSON.parse(localStorage.getItem(this.key));
  }
}

class SessionStore extends BaseStore {
  constructor() {
    super('session');
  }
}

class SessionView {
  constructor(element) {
    this.element = element;
    this.store = new SessionStore();
  }

  async signIn(email, password) {
    try {
      const response = await fetch('https://api.example.com/sign-in', {
        method: 'POST',
        body: JSON.stringify({ email, password }),
      });
      const user = await response.json();
      localStorage.setItem('session', JSON.stringify(user));
      this.element.textContent = user.profile.name;
    } catch (error) {}
  }
}

module.exports = { BaseStore, SessionStore, SessionView };
```

Review it before I merge. I want to decide afterwards which problems are worth fixing now
and which can wait, so keep them separable.
