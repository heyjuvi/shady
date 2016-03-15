public class Program
{
    public static void main(string[] args)
    {
        Gtk.init(ref args);

        Shady shady = new Shady();
        shady.destroy.connect(Gtk.main_quit);
        shady.show_all();

        Gtk.main();
    }
}
