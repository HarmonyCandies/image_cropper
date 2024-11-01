type VoidCallback = () => void;

export class ChangeNotifier {
  private _count: number = 0;
  private static _emptyListeners: Array<VoidCallback | null> = new Array(0).fill(null);
  private _listeners: Array<VoidCallback | null> = ChangeNotifier._emptyListeners;
  private _notificationCallStackDepth: number = 0;
  private _reentrantlyRemovedListeners: number = 0;
  private _debugDisposed: boolean = false;

  private static debugAssertNotDisposed(notifier: ChangeNotifier): void {
    if (notifier._debugDisposed) {
      throw new Error(`A ${notifier.constructor.name} was used after being disposed.`);
    }
  }

  protected get hasListeners(): boolean {
    return this._count > 0;
  }

  public addListener(listener: VoidCallback): void {
    ChangeNotifier.debugAssertNotDisposed(this);

    if (this._count === this._listeners.length) {
      const newListeners: Array<VoidCallback | null> = new Array(this._listeners.length * 2).fill(null);
      for (let i = 0; i < this._count; i++) {
        newListeners[i] = this._listeners[i];
      }
      this._listeners = newListeners;
    }
    this._listeners[this._count++] = listener;
  }

  public removeListener(listener: VoidCallback): void {
    ChangeNotifier.debugAssertNotDisposed(this);
    for (let i = 0; i < this._count; i++) {
      const listenerAtIndex = this._listeners[i];
      if (listenerAtIndex === listener) {
        if (this._notificationCallStackDepth > 0) {
          this._listeners[i] = null;
          this._reentrantlyRemovedListeners++;
        } else {
          this._removeAt(i);
        }
        break;
      }
    }
  }

  private _removeAt(index: number): void {
    this._count--;
    if (this._count * 2 <= this._listeners.length) {
      const newListeners: Array<VoidCallback | null> = new Array(this._count).fill(null);
      for (let i = 0; i < index; i++) {
        newListeners[i] = this._listeners[i];
      }
      for (let i = index; i < this._count; i++) {
        newListeners[i] = this._listeners[i + 1];
      }
      this._listeners = newListeners;
    } else {
      for (let i = index; i < this._count; i++) {
        this._listeners[i] = this._listeners[i + 1];
      }
      this._listeners[this._count] = null;
    }
  }

  public dispose(): void {
    ChangeNotifier.debugAssertNotDisposed(this);
    if (this._notificationCallStackDepth !== 0) {
      throw new Error(`Dispose was called during notifyListeners.`);
    }
    this._debugDisposed = true;
    this._listeners = ChangeNotifier._emptyListeners;
    this._count = 0;
  }

  public notifyListeners(): void {
    ChangeNotifier.debugAssertNotDisposed(this);
    if (this._count === 0) {
      return;
    }

    this._notificationCallStackDepth++;
    const end = this._count;

    for (let i = 0; i < end; i++) {
      try {
        this._listeners[i]?.();
      } catch (error) {
        console.error(`Error while dispatching notifications for ${this.constructor.name}:`, error);
      }
    }

    this._notificationCallStackDepth--;

    if (this._notificationCallStackDepth === 0 && this._reentrantlyRemovedListeners > 0) {
      const newLength = this._count - this._reentrantlyRemovedListeners;
      if (newLength * 2 <= this._listeners.length) {
        const newListeners: Array<VoidCallback | null> = new Array(newLength).fill(null);
        let newIndex = 0;
        for (let i = 0; i < this._count; i++) {
          const listener = this._listeners[i];
          if (listener !== null) {
            newListeners[newIndex++] = listener;
          }
        }
        this._listeners = newListeners;
      } else {
        for (let i = 0; i < newLength; i++) {
          if (this._listeners[i] === null) {
            let swapIndex = i + 1;
            while (this._listeners[swapIndex] === null) {
              swapIndex++;
            }
            this._listeners[i] = this._listeners[swapIndex];
            this._listeners[swapIndex] = null;
          }
        }
      }

      this._reentrantlyRemovedListeners = 0;
      this._count = newLength;
    }
  }
}
