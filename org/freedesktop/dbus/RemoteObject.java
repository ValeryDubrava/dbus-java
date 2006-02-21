package org.freedesktop.dbus;

class RemoteObject
{
   String service;
   String objectpath;
   Class iface;
   public RemoteObject(String service, String objectpath, Class iface)
   {
      this.service = service;
      this.objectpath = objectpath;
      this.iface = iface;
   }
   public boolean equals(Object o)
   {
      if (!(o instanceof RemoteObject)) return false;
      RemoteObject them = (RemoteObject) o;
      if (!them.service.equals(this.service)) return false;
      if (!them.objectpath.equals(this.objectpath)) return false;
      if (!them.iface.equals(this.iface)) return false;
      return true;
   }
   public int hashCode()
   {
      return service.hashCode() + objectpath.hashCode() + iface.hashCode();
   }
}
