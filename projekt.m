classdef projekt < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure              matlab.ui.Figure
        PoLabel               matlab.ui.control.Label
        PrzedLabel            matlab.ui.control.Label
        PrzeksztaobrazButton  matlab.ui.control.Button
        UczsieButton          matlab.ui.control.StateButton
        WczytajobrazButton    matlab.ui.control.Button
        UIAxes_2              matlab.ui.control.UIAxes
        UIAxes                matlab.ui.control.UIAxes
    end



% Related documentation
    properties (Access = public)
        obrazwyjsciowy % Obraz wyświetlany po przekształceniu
        obrazwejsciowy % Obraz wczytany przez użytkownika
        rgbmodels % modele sieci neuronowej dla poszczególnych kanałów
        szerokoscObrazuWczytanego % szerokosc obrazu wczytanego przez uzytkownika
        wysokoscObrazuWczytanego % wysokosc obrazu wczytanego przez uzytkownika
        imageSizeOk % zmienna do kontrolowania czy obraz ma właściwe wymiary,
        gsize % rozmiar fragmentu obrazu
        arr % tablica pomocnicza
    end
    
    

    % Callbacks that handle component events
    methods (Access = private)

        % Value changed function: UczsieButton
        function UczsieButtonValueChanged(app, event)
            app.UczsieButton.Enable='off';
            app.WczytajobrazButton.Enable='off';
            app.PrzeksztaobrazButton.Enable='off';
            app.gsize=10;
            xsize=1600/app.gsize;
            ysize=1200/app.gsize;
            in = ones(22,1600,1200,3);
            out= ones(22,1600,1200,3);
            f=uifigure;
            uialert(f,'Naciśnij OK i poczekaj na komunikat o gotowości sieci neuronowej','Info','Icon','info','CloseFcn','uiresume(gcbf)');
            uiwait(gcbf);
            d = uiprogressdlg(f,'Title','Proszę czekać','Message','Trwa uczenie sieci neuronowej');
            app.rgbmodels={feedforwardnet(20),feedforwardnet(20),feedforwardnet(20)};
            iloscObrazowDoUczeniaSieci = 22;
            len=xsize*ysize;
            x=ones(len,1);
            y=ones(len,1);
            superPasekLadowania=1.0/(iloscObrazowDoUczeniaSieci+1);
            for i=1:iloscObrazowDoUczeniaSieci
                d.Value=superPasekLadowania*i;
                s = sprintf('./TAK/a/%da.jpeg', i);
                in(i,:,:,:) = double(imread(s))/255;
                s = sprintf('./TAK/b/%db.jpeg', i);
                out(i,:,:,:) = double(imread(s))/255;
                for u=1:3
                    for v=1:xsize
                        for b=1:ysize
                            g=mean(mean(in(i,(v-1)*app.gsize+1:v*app.gsize,(b-1)*app.gsize+1:b*app.gsize,u)));
                            x((v-1)*ysize+b)=mean(g);
                            h=mean(mean(out(i,(v-1)*app.gsize+1:v*app.gsize,(b-1)*app.gsize+1:b*app.gsize,u)));
                            y((v-1)*ysize+b)=h-g;
                        end
                    end
                    app.rgbmodels{u}.trainParam.showWindow=0;
                    app.rgbmodels{u}=train(app.rgbmodels{u},x',y');
                end
            end
            app.arr=ones(3,1001);
            for u=1:3
                app.arr(u,:)=0:0.001:1;
                for e=1:1000
                      app.arr(u,e)=app.rgbmodels{u}(app.arr(u,e)); 
                end
            end
            d.Value=1.0;
            pause(0.5);
            uialert(f,'Sieć neuronowa gotowa do użycia.','Success','Icon','success','CloseFcn',@(h,e)close(f));%@(h,e)close(f) - usuwanie bledu zostajacego okna 
            app.WczytajobrazButton.Enable='on';
            app.PrzeksztaobrazButton.Enable='on';
        end

        % Button pushed function: WczytajobrazButton
        function WczytajobrazButtonPushed(app, event)
            app.PrzeksztaobrazButton.Enable='off';
            app.WczytajobrazButton.Enable='off';
            if(app.UczsieButton.Value==true)
                [file,path] = uigetfile('*.jpeg;*.jpg;*.png');
                app.obrazwejsciowy = fullfile(path,file);
                if isequal(file,0)
                   f=uifigure; 
                   uialert(f,'Błąd wczytywania obrazu.','Error','Icon','error','CloseFcn',@(h,e)close(f));%wyswieta sie gdy uzytkownik anuluje
                else
                    in=imread(app.obrazwejsciowy);
                    in=double(in)/255;
                    if(size(in,1)>size(in,2))
                        n=size(in,1);
                    else
                        n=size(in,2);
                    end
                    app.imageSizeOk=mod(n,app.gsize);
                    if(app.imageSizeOk==0)
                        disableDefaultInteractivity(app.UIAxes); % rozwiazanie bledow z niepoprawnym zachowaniem wyswietlanego obrazka 
                        imshow(in,'Parent',app.UIAxes);
                    else
                        f=uifigure; 
                        uialert(f,'Nieprawidłowe wymiary wczytanego obrazu. Wymiary wczytywanego obrazu muszą być podzielne przez 10. Zmień wymiary lub wczytaj inny obraz.','Error','Icon','error','CloseFcn',@(h,e)close(f));
                    end
                   
                end    
            else
               f=uifigure;
               uialert(f,'Przed wczytaniem obrazu musisz nacisnąć przycisk "Ucz sieć"','Error','Icon','error','CloseFcn',@(h,e)close(f));
            end
            app.PrzeksztaobrazButton.Enable='on';
            app.WczytajobrazButton.Enable='on';
        end

        % Button pushed function: PrzeksztaobrazButton
        function PrzeksztaobrazButtonPushed(app, event)
            app.WczytajobrazButton.Enable='off';
            app.PrzeksztaobrazButton.Enable='off';
            if isempty(app.obrazwejsciowy)
                  f=uifigure; 
                  uialert(f,'Błąd! Nie wczytałeś obrazu!.','Error','Icon','error','CloseFcn',@(h,e)close(f)); 
            else
               if(app.imageSizeOk==0)
                    f=uifigure;
                    uialert(f,'Naciśnij OK i poczekaj na komunikat o ukończeniu przetwarzania obrazu. ','Info','Icon','info','CloseFcn','uiresume(gcbf)');
                    uiwait(gcbf);
                    d = uiprogressdlg(f,'Title','Proszę czekać','Message','Trwa przetwarzanie obrazu');
                    in=imread(app.obrazwejsciowy);
                    in=double(in)/255;
                    app.szerokoscObrazuWczytanego=size(in,1);
                    app.wysokoscObrazuWczytanego=size(in,2);
                    xsize=app.szerokoscObrazuWczytanego/app.gsize;
                    ysize=app.wysokoscObrazuWczytanego/app.gsize;
                    app.obrazwyjsciowy=in;
                    pasekLadowaniaAleTrudniejszy=1.0/((xsize+1)*(ysize+1)*3);
                    iterator=0;
                    for u=1:3     
                        for v=1:xsize
                            for b=1:ysize
                                iterator=iterator+1;
                                d.Value = pasekLadowaniaAleTrudniejszy*iterator;
                                g=mean(mean(in((v-1)*app.gsize+1:v*app.gsize,(b-1)*app.gsize+1:b*app.gsize,u)));
                                val=app.arr(u,max(round(g*1000),1));
                                app.obrazwyjsciowy((v-1)*app.gsize+1:v*app.gsize,(b-1)*app.gsize+1:b*app.gsize,u)=val+in((v-1)*app.gsize+1:v*app.gsize,(b-1)*app.gsize+1:b*app.gsize,u);
                            end
                        end
                    end
                    d.Value=1.0;
                    pause(0.5);
                    uialert(f,'Przetwarzanie obrazu zostało zakończone.','Success','Icon','success','CloseFcn',@(h,e)close(f));
                    imshow(app.obrazwyjsciowy,'Parent',app.UIAxes_2);        
               else
                    f=uifigure; 
                    uialert(f,'Nieprawidłowe wymiary wczytanego obrazu. Wczytaj inny obraz','Error','Icon','error','CloseFcn',@(h,e)close(f));
               end 
            end
            app.WczytajobrazButton.Enable='on';
            app.PrzeksztaobrazButton.Enable='on';
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Color = [0.149 0.149 0.149];
            app.UIFigure.Position = [100 100 1024 768];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.Resize = 'off';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Toolbar.Visible = 'off';
            app.UIAxes.Color = [0.149 0.149 0.149];
            app.UIAxes.Visible = 'off';
            app.UIAxes.Position = [68 46 369 454];

            % Create UIAxes_2
            app.UIAxes_2 = uiaxes(app.UIFigure);
            zlabel(app.UIAxes_2, 'Z')
            app.UIAxes_2.Toolbar.Visible = 'off';
            app.UIAxes_2.Color = [0.149 0.149 0.149];
            app.UIAxes_2.Visible = 'off';
            app.UIAxes_2.Position = [585 46 369 454];

            % Create WczytajobrazButton
            app.WczytajobrazButton = uibutton(app.UIFigure, 'push');
            app.WczytajobrazButton.ButtonPushedFcn = createCallbackFcn(app, @WczytajobrazButtonPushed, true);
            app.WczytajobrazButton.BackgroundColor = [1 1 0.0667];
            app.WczytajobrazButton.FontSize = 16;
            app.WczytajobrazButton.FontWeight = 'bold';
            app.WczytajobrazButton.FontColor = [0.149 0.149 0.149];
            app.WczytajobrazButton.Position = [414 626 198 59];
            app.WczytajobrazButton.Text = {'Wczytaj obraz'; ''};

            % Create UczsieButton
            app.UczsieButton = uibutton(app.UIFigure, 'state');
            app.UczsieButton.ValueChangedFcn = createCallbackFcn(app, @UczsieButtonValueChanged, true);
            app.UczsieButton.Text = 'Ucz sieć';
            app.UczsieButton.BackgroundColor = [1 1 0.0667];
            app.UczsieButton.FontSize = 16;
            app.UczsieButton.FontWeight = 'bold';
            app.UczsieButton.Position = [154 629 198 56];

            % Create PrzeksztaobrazButton
            app.PrzeksztaobrazButton = uibutton(app.UIFigure, 'push');
            app.PrzeksztaobrazButton.ButtonPushedFcn = createCallbackFcn(app, @PrzeksztaobrazButtonPushed, true);
            app.PrzeksztaobrazButton.BackgroundColor = [1 1 0.0667];
            app.PrzeksztaobrazButton.FontSize = 16;
            app.PrzeksztaobrazButton.FontWeight = 'bold';
            app.PrzeksztaobrazButton.FontColor = [0.149 0.149 0.149];
            app.PrzeksztaobrazButton.Position = [671 626 198 59];
            app.PrzeksztaobrazButton.Text = {'Przekształć obraz'; ''};

            % Create PrzedLabel
            app.PrzedLabel = uilabel(app.UIFigure);
            app.PrzedLabel.FontSize = 16;
            app.PrzedLabel.FontWeight = 'bold';
            app.PrzedLabel.FontColor = [1 1 0.0667];
            app.PrzedLabel.Position = [46 534 109 22];
            app.PrzedLabel.Text = 'Przed:';

            % Create PoLabel
            app.PoLabel = uilabel(app.UIFigure);
            app.PoLabel.FontSize = 16;
            app.PoLabel.FontWeight = 'bold';
            app.PoLabel.FontColor = [1 1 0.0667];
            app.PoLabel.Position = [541 534 102 22];
            app.PoLabel.Text = 'Po:';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = projekt

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end