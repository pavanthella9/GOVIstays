const { test, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, setDoc, updateDoc, deleteDoc, writeBatch, serverTimestamp, getDoc, Timestamp } = require('firebase/firestore');

let env;
const projectId = 'govistays-rules-test';
const user = (uid) => env.authenticatedContext(uid).firestore();
const booking = (db) => doc(db, 'bookings', 'booking-1');
const audit = (db, id) => doc(db, 'bookings', 'booking-1', 'guestEventAudit', id);
const stamp = () => serverTimestamp();

before(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: fs.readFileSync('firestore.rules', 'utf8')
    }
  });
});
after(async () => { if (env) await env.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    await setDoc(doc(db, 'users', 'admin-1'), { role: 'admin', active: true });
    await setDoc(doc(db, 'users', 'staff-1'), { role: 'staff', active: true });
    await setDoc(doc(db, 'users', 'inactive-1'), { role: 'staff', active: false });
    await setDoc(booking(db), { customerName: 'Guest', totalAmount: 2000, advanceAmount: 500, balanceAmount: 1500 });
  });
});

test('active users can read bookings; inactive and anonymous cannot', async () => {
  await assertSucceeds(getDoc(booking(user('staff-1'))));
  await assertFails(getDoc(booking(user('inactive-1'))));
  await assertFails(getDoc(booking(env.unauthenticatedContext().firestore())));
});
test('staff cannot edit financial amounts or delete bookings', async () => {
  await assertFails(updateDoc(booking(user('staff-1')), { totalAmount: 0 }));
  await assertFails(deleteDoc(booking(user('staff-1'))));
});
test('staff can atomically mark arrival with audit record', async () => {
  const db = user('staff-1');
  const batch = writeBatch(db);
  batch.update(booking(db), { actualCheckIn: stamp(), checkInMarkedBy: 'staff-1' });
  batch.set(audit(db, 'arrival-1'), { event: 'checkIn', action: 'mark', actorUid: 'staff-1', oldTime: null, newTime: stamp(), createdAt: stamp() });
  await assertSucceeds(batch.commit());
});
test('staff cannot check out before arrival', async () => {
  const db = user('staff-1');
  await assertFails(updateDoc(booking(db), { actualCheckOut: stamp(), checkOutMarkedBy: 'staff-1' }));
});
test('staff cannot forge corrections or backdate check-in', async () => {
  const db = user('staff-1');
  await assertFails(updateDoc(booking(db), { actualCheckIn: Timestamp.fromDate(new Date('2026-01-01')), checkInMarkedBy: 'staff-1' }));
  await assertFails(setDoc(audit(db, 'fake'), { event: 'checkIn', action: 'correct', actorUid: 'staff-1', oldTime: null, newTime: stamp(), createdAt: stamp() }));
});
test('staff cannot mark arrival twice', async () => {
  const db = user('staff-1');
  await assertSucceeds(updateDoc(booking(db), { actualCheckIn: stamp(), checkInMarkedBy: 'staff-1' }));
  await assertFails(updateDoc(booking(db), { actualCheckIn: stamp(), checkInMarkedBy: 'staff-1' }));
});
test('staff can mark departure after arrival, but not twice', async () => {
  const db = user('staff-1');
  await assertSucceeds(updateDoc(booking(db), { actualCheckIn: stamp(), checkInMarkedBy: 'staff-1' }));
  const batch = writeBatch(db);
  batch.update(booking(db), { actualCheckOut: stamp(), checkOutMarkedBy: 'staff-1' });
  batch.set(audit(db, 'departure-1'), { event: 'checkOut', action: 'mark', actorUid: 'staff-1', oldTime: null, newTime: stamp(), createdAt: stamp() });
  await assertSucceeds(batch.commit());
  await assertFails(updateDoc(booking(db), { actualCheckOut: stamp(), checkOutMarkedBy: 'staff-1' }));
});
test('admin may correct timestamps and write correction audit', async () => {
  const db = user('admin-1');
  await assertSucceeds(updateDoc(booking(db), { actualCheckIn: Timestamp.fromDate(new Date('2026-01-01')), checkInMarkedBy: 'admin-1' }));
  await assertSucceeds(setDoc(audit(db, 'correction-1'), { event: 'checkIn', action: 'correct', actorUid: 'admin-1', oldTime: null, newTime: Timestamp.fromDate(new Date('2026-01-01')), createdAt: stamp() }));
});
test('audit entries cannot be modified or deleted', async () => {
  const db = user('admin-1');
  await assertSucceeds(setDoc(audit(db, 'entry-1'), { event: 'checkIn', action: 'mark', actorUid: 'admin-1', oldTime: null, newTime: stamp(), createdAt: stamp() }));
  await assertFails(updateDoc(audit(db, 'entry-1'), { action: 'correct' }));
  await assertFails(deleteDoc(audit(db, 'entry-1')));
});
